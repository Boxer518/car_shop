globalThis.asList = function(value) {
  if (!value) {
    return []
  }
  if (Array.isArray(value)) {
    return value
  }
  return [value]
}

globalThis.parseTime = function(value) {
  return Date.parse(String(value).replace(" ", "T"))
}

globalThis.automaticPercent = function(year, mileage) {
  let percent = 0
  if (mileage >= 100000) {
    percent += 5
  }
  if (new Date().getUTCFullYear() - year >= 5) {
    percent += 3
  }
  return percent
}

globalThis.roleCap = function(role) {
  return role === "director" ? 25 : 15
}

globalThis.quote = function(base, optionsTotal, year, mileage, manual, role) {
  const cap = globalThis.roleCap(role)
  const automatic = globalThis.automaticPercent(year, mileage)
  const total = Math.min(cap, Math.max(0, automatic + manual))
  const finalPrice = Math.round(((base + optionsTotal) * (100 - total)) / 100)
  return { automatic: automatic, total: total, finalPrice: finalPrice, cap: cap }
}

globalThis.optionSum = function(app, car) {
  const ids = globalThis.asList(car.get("options"))
  let sum = 0
  for (let i = 0; i < ids.length; i++) {
    const option = app.findRecordById("options", ids[i])
    sum += Number(option.get("price"))
  }
  return sum
}

globalThis.fieldError = function(status, field, message) {
  const data = {}
  data[field] = new ValidationError("invalid_" + field, message)
  throw new ApiError(status, message, data)
}

globalThis.assertDrive = function(app, record) {
  const start = globalThis.parseTime(record.get("startsAt"))
  const end = globalThis.parseTime(record.get("endsAt"))
  if (!start || !end || end <= start) {
    globalThis.fieldError(422, "endsAt", "Окончание должно быть позже начала")
  }
  const minutes = (end - start) / 60000
  if (minutes < 30 || minutes > 180) {
    globalThis.fieldError(422, "endsAt", "Тест-драйв длится от 30 минут до 3 часов")
  }
  const rows = app.findRecordsByFilter(
    "test_drives",
    'car = {:car} && deleted = false && status != "cancelled" && id != {:id}',
    "",
    200,
    0,
    { car: record.get("car"), id: record.id },
  )
  for (let i = 0; i < rows.length; i++) {
    const otherStart = globalThis.parseTime(rows[i].get("startsAt"))
    const otherEnd = globalThis.parseTime(rows[i].get("endsAt"))
    if (start < otherEnd && otherStart < end) {
      globalThis.fieldError(409, "startsAt", "Автомобиль уже занят в этот интервал")
    }
  }
}

globalThis.assertDeal = function(app, record, auth) {
  const role = auth ? auth.get("role") : ""
  if (role !== "manager" && role !== "director") {
    throw new ForbiddenError("Сделку оформляет менеджер")
  }
  const manual = Number(record.get("discountPercent"))
  const cap = globalThis.roleCap(role)
  if (manual < 0 || manual > cap) {
    globalThis.fieldError(422, "discountPercent", "Скидка для этой роли не больше " + cap + "%")
  }
  const car = app.findRecordById("cars", record.get("car"))
  if (car.get("status") === "sold" && car.get("deleted") !== true) {
    const sameCar = app.findRecordsByFilter(
      "deals",
      "car = {:car} && deleted = false && id != {:id}",
      "",
      1,
      0,
      { car: car.id, id: record.id },
    )
    if (sameCar.length > 0) {
      globalThis.fieldError(409, "car", "Автомобиль уже продан")
    }
  }
  const priced = globalThis.quote(
    Number(car.get("price")),
    globalThis.optionSum(app, car),
    Number(car.get("year")),
    Number(car.get("mileage")),
    manual,
    role,
  )
  const sent = Number(record.get("finalPrice"))
  if (sent && Math.abs(sent - priced.finalPrice) > 1) {
    globalThis.fieldError(409, "finalPrice", "Итоговая цена не сходится с правилами салона")
  }
  record.set("basePrice", Number(car.get("price")))
  record.set("optionsTotal", globalThis.optionSum(app, car))
  record.set("automaticPercent", priced.automatic)
  record.set("finalPrice", priced.finalPrice)
  if (!record.get("manager") && auth) {
    record.set("manager", auth.id)
  }
}

onRecordCreateRequest((e) => {
  const auth = e.auth
  const director = auth && auth.get("role") === "director"
  if (!director) {
    e.record.set("role", "buyer")
  }
  if (!e.record.get("role")) {
    e.record.set("role", "buyer")
  }
  e.next()
  if (e.record.get("role") === "buyer" && !e.record.get("customer")) {
    const customers = e.app.findCollectionByNameOrId("customers")
    const customer = new Record(customers)
    customer.set("fullName", e.record.get("fullName"))
    customer.set("email", e.record.get("email"))
    customer.set("phone", e.record.get("phone"))
    customer.set("user", e.record.id)
    customer.set("deleted", false)
    e.app.save(customer)
    e.record.set("customer", customer.id)
    e.app.save(e.record)
  }
}, "users")

onRecordCreateRequest((e) => {
  const auth = e.auth
  const role = auth ? auth.get("role") : ""
  const manual = Number(e.record.get("discountPercent"))
  const cap = role === "director" ? 25 : 15
  if (manual < 0 || manual > cap) {
    throw new ApiError(422, "Скидка для этой роли не больше " + cap + "%", {
      discountPercent: new ValidationError("invalid_discount", "Скидка для этой роли не больше " + cap + "%"),
    })
  }
  const car = e.app.findRecordById("cars", e.record.get("car"))
  const sameCar = e.app.findRecordsByFilter("deals", "car = {:car} && deleted = false && id != {:id}", "", 1, 0, { car: car.id, id: e.record.id })
  if (car.get("status") === "sold" && sameCar.length > 0) {
    throw new ApiError(409, "Автомобиль уже продан", { car: new ValidationError("conflict", "Автомобиль уже продан") })
  }
  let optionsTotal = 0
  const rawOptions = car.get("options")
  const ids = !rawOptions ? [] : Array.isArray(rawOptions) ? rawOptions : [rawOptions]
  for (let i = 0; i < ids.length; i++) optionsTotal += Number(e.app.findRecordById("options", ids[i]).get("price"))
  let automatic = 0
  if (Number(car.get("mileage")) >= 100000) automatic += 5
  if (new Date().getUTCFullYear() - Number(car.get("year")) >= 5) automatic += 3
  const total = Math.min(cap, automatic + manual)
  const finalPrice = Math.round(((Number(car.get("price")) + optionsTotal) * (100 - total)) / 100)
  const sent = Number(e.record.get("finalPrice"))
  if (sent && Math.abs(sent - finalPrice) > 1) {
    throw new ApiError(409, "Итоговая цена не сходится с правилами салона", { finalPrice: new ValidationError("conflict", "Итоговая цена не сходится с правилами салона") })
  }
  e.record.set("basePrice", Number(car.get("price")))
  e.record.set("optionsTotal", optionsTotal)
  e.record.set("automaticPercent", automatic)
  e.record.set("finalPrice", finalPrice)
  if (!e.record.get("manager") && auth) e.record.set("manager", auth.id)
  e.next()
  car.set("status", "sold")
  e.app.save(car)
}, "deals")

onRecordCreateRequest((e) => {
  if (!e.record.get("status")) e.record.set("status", "planned")
  const start = Date.parse(String(e.record.get("startsAt")).replace(" ", "T"))
  const end = Date.parse(String(e.record.get("endsAt")).replace(" ", "T"))
  if (!start || !end || end <= start) {
    throw new ApiError(422, "Окончание должно быть позже начала", { endsAt: new ValidationError("invalid_endsAt", "Окончание должно быть позже начала") })
  }
  const minutes = (end - start) / 60000
  if (minutes < 30 || minutes > 180) {
    throw new ApiError(422, "Тест-драйв длится от 30 минут до 3 часов", { endsAt: new ValidationError("invalid_endsAt", "Тест-драйв длится от 30 минут до 3 часов") })
  }
  const rows = e.app.findRecordsByFilter("test_drives", 'car = {:car} && deleted = false && status != "cancelled" && id != {:id}', "", 200, 0, { car: e.record.get("car"), id: e.record.id })
  for (let i = 0; i < rows.length; i++) {
    const otherStart = Date.parse(String(rows[i].get("startsAt")).replace(" ", "T"))
    const otherEnd = Date.parse(String(rows[i].get("endsAt")).replace(" ", "T"))
    if (start < otherEnd && otherStart < end) {
      throw new ApiError(409, "Автомобиль уже занят в этот интервал", { startsAt: new ValidationError("conflict", "Автомобиль уже занят в этот интервал") })
    }
  }
  e.next()
}, "test_drives")

onRecordDeleteRequest((e) => {
  const name = e.collection.name
  const id = e.record.id
  function blocked(collection, filter, params, message) {
    const rows = e.app.findRecordsByFilter(collection, filter, "", 1, 0, params)
    if (rows.length > 0) {
      throw new ApiError(409, message, {
        id: new ValidationError("conflict", message),
      })
    }
  }
  if (name === "brands") {
    blocked("models", "brand = {:id} && deleted = false", { id: id }, "У марки есть модели")
  }
  if (name === "models") {
    blocked("cars", "model = {:id} && deleted = false", { id: id }, "У модели есть автомобили")
  }
  if (name === "cars") {
    blocked("deals", "car = {:id} && deleted = false", { id: id }, "По автомобилю есть сделки")
    blocked("passports", "car = {:id} && deleted = false", { id: id }, "У автомобиля есть ПТС")
  }
  if (name === "customers") {
    blocked("deals", "customer = {:id} && deleted = false", { id: id }, "У клиента есть сделки")
  }
  if (name === "options") {
    blocked("cars", "options.id ?= {:id} && deleted = false", { id: id }, "Опция стоит на автомобилях")
  }
  e.next()
})

routerAdd("GET", "/api/salon/report", (e) => {
  if (!e.auth || e.auth.get("role") !== "director") {
    throw new ForbiddenError("Отчёт доступен директору")
  }
  const cars = e.app.findRecordsByFilter("cars", "deleted = false", "", 500, 0)
  const deals = e.app.findRecordsByFilter("deals", "deleted = false", "", 500, 0)
  const drives = e.app.findRecordsByFilter(
    "test_drives",
    'deleted = false && status = "planned"',
    "",
    500,
    0,
  )
  let inStock = 0
  let reserved = 0
  let sold = 0
  for (let i = 0; i < cars.length; i++) {
    const status = cars[i].get("status")
    if (status === "in_stock") inStock++
    else if (status === "reserved") reserved++
    else if (status === "sold") sold++
  }
  let dealsSum = 0
  const byBrand = {}
  for (let i = 0; i < deals.length; i++) {
    const price = Number(deals[i].get("finalPrice"))
    dealsSum += price
    let brandName = "Без марки"
    try {
      const car = e.app.findRecordById("cars", deals[i].get("car"))
      const model = e.app.findRecordById("models", car.get("model"))
      const brand = e.app.findRecordById("brands", model.get("brand"))
      brandName = brand.get("name")
    } catch (_) {}
    if (!byBrand[brandName]) {
      byBrand[brandName] = { brand: brandName, count: 0, sum: 0 }
    }
    byBrand[brandName].count++
    byBrand[brandName].sum += price
  }
  const rows = []
  const keys = Object.keys(byBrand)
  for (let i = 0; i < keys.length; i++) {
    rows.push(byBrand[keys[i]])
  }
  return e.json(200, {
    carsInStock: inStock,
    carsReserved: reserved,
    carsSold: sold,
    dealsCount: deals.length,
    dealsSum: dealsSum,
    plannedDrives: drives.length,
    byBrand: rows,
  })
}, $apis.requireAuth("users"))

routerAdd("POST", "/api/salon/quote", (e) => {
  if (!e.auth) {
    throw new UnauthorizedError("Нужен вход")
  }
  const body = e.requestInfo().body
  const car = e.app.findRecordById("cars", body.car)
  let optionsTotal = 0
  const rawOptions = car.get("options")
  const ids = !rawOptions ? [] : Array.isArray(rawOptions) ? rawOptions : [rawOptions]
  for (let i = 0; i < ids.length; i++) {
    optionsTotal += Number(e.app.findRecordById("options", ids[i]).get("price"))
  }
  const manual = Number(body.discountPercent || 0)
  const role = e.auth.get("role")
  const cap = role === "director" ? 25 : 15
  let automatic = 0
  if (Number(car.get("mileage")) >= 100000) automatic += 5
  if (new Date().getUTCFullYear() - Number(car.get("year")) >= 5) automatic += 3
  const total = Math.min(cap, Math.max(0, automatic + manual))
  const base = Number(car.get("price"))
  return e.json(200, {
    basePrice: base,
    optionsTotal: optionsTotal,
    automaticPercent: automatic,
    totalPercent: total,
    finalPrice: Math.round(((base + optionsTotal) * (100 - total)) / 100),
    cap: cap,
  })
}, $apis.requireAuth("users"))
