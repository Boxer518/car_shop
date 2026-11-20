migrate((app) => {
  const settings = app.settings()
  settings.meta.appName = "Автосалон"
  settings.meta.appURL = "http://127.0.0.1:8090"
  app.save(settings)

  const superusers = app.findCollectionByNameOrId("_superusers")
  let panelAdmin = null
  try {
    panelAdmin = app.findAuthRecordByEmail("_superusers", "admin@salon.local")
  } catch (_) {}
  if (!panelAdmin) {
    panelAdmin = new Record(superusers)
    panelAdmin.set("email", "admin@salon.local")
    panelAdmin.set("password", "admin12345")
    app.save(panelAdmin)
  }

  const users = app.findCollectionByNameOrId("users")
  users.fields.add(new Field({
    name: "fullName",
    type: "text",
    required: true,
    min: 2,
    max: 120,
  }))
  users.fields.add(new Field({
    name: "phone",
    type: "text",
    required: true,
    min: 10,
    max: 16,
  }))
  users.fields.add(new Field({
    name: "role",
    type: "select",
    required: true,
    maxSelect: 1,
    values: ["buyer", "manager", "director"],
  }))
  users.listRule = '@request.auth.role = "director"'
  users.viewRule = '@request.auth.role = "director" || id = @request.auth.id'
  users.createRule = '@request.auth.id = "" || @request.auth.role = "director"'
  users.updateRule = '@request.auth.role = "director" || id = @request.auth.id'
  users.deleteRule = '@request.auth.role = "director"'
  users.manageRule = '@request.auth.role = "director"'
  app.save(users)

  const staff = '@request.auth.role = "manager" || @request.auth.role = "director"'
  const director = '@request.auth.role = "director"'
  const signed = '@request.auth.id != ""'
  const visible = signed + ' && (deleted = false || ' + staff + ')'

  const brands = new Collection({
    type: "base",
    name: "brands",
    listRule: visible,
    viewRule: visible,
    createRule: staff,
    updateRule: staff,
    deleteRule: director,
    fields: [
      { name: "name", type: "text", required: true, min: 2, max: 80 },
      { name: "country", type: "text", required: true, min: 2, max: 60 },
      { name: "deleted", type: "bool" },
    ],
    indexes: ["CREATE UNIQUE INDEX idx_brands_name ON brands (name)"],
  })
  app.save(brands)

  const models = new Collection({
    type: "base",
    name: "models",
    listRule: visible,
    viewRule: visible,
    createRule: staff,
    updateRule: staff,
    deleteRule: director,
    fields: [
      {
        name: "brand",
        type: "relation",
        required: true,
        collectionId: brands.id,
        minSelect: 1,
        maxSelect: 1,
        cascadeDelete: false,
      },
      { name: "name", type: "text", required: true, min: 1, max: 80 },
      {
        name: "bodyType",
        type: "select",
        required: true,
        maxSelect: 1,
        values: ["sedan", "suv", "hatchback", "coupe", "wagon", "van"],
      },
      { name: "seats", type: "number", required: true, onlyInt: true, min: 2, max: 9 },
      { name: "deleted", type: "bool" },
    ],
    indexes: ["CREATE UNIQUE INDEX idx_models_brand_name ON models (brand, name)"],
  })
  app.save(models)

  const options = new Collection({
    type: "base",
    name: "options",
    listRule: visible,
    viewRule: visible,
    createRule: staff,
    updateRule: staff,
    deleteRule: director,
    fields: [
      { name: "name", type: "text", required: true, min: 2, max: 80 },
      { name: "price", type: "number", required: true, onlyInt: true, min: 0, max: 2000000 },
      { name: "deleted", type: "bool" },
    ],
    indexes: ["CREATE UNIQUE INDEX idx_options_name ON options (name)"],
  })
  app.save(options)

  const cars = new Collection({
    type: "base",
    name: "cars",
    listRule: visible,
    viewRule: visible,
    createRule: staff,
    updateRule: staff,
    deleteRule: director,
    fields: [
      {
        name: "model",
        type: "relation",
        required: true,
        collectionId: models.id,
        minSelect: 1,
        maxSelect: 1,
        cascadeDelete: false,
      },
      { name: "vin", type: "text", required: true, min: 17, max: 17 },
      { name: "year", type: "number", required: true, onlyInt: true, min: 1990, max: 2026 },
      { name: "price", type: "number", required: true, onlyInt: true, min: 100000, max: 50000000 },
      { name: "mileage", type: "number", required: true, onlyInt: true, min: 0, max: 1000000 },
      { name: "color", type: "text", required: true, min: 2, max: 40 },
      {
        name: "status",
        type: "select",
        required: true,
        maxSelect: 1,
        values: ["in_stock", "reserved", "sold"],
      },
      {
        name: "options",
        type: "relation",
        required: false,
        collectionId: options.id,
        minSelect: 0,
        maxSelect: 20,
        cascadeDelete: false,
      },
      { name: "deleted", type: "bool" },
    ],
    indexes: ["CREATE UNIQUE INDEX idx_cars_vin ON cars (vin)"],
  })
  app.save(cars)

  const customers = new Collection({
    type: "base",
    name: "customers",
    listRule: staff + " || user = @request.auth.id",
    viewRule: staff + " || user = @request.auth.id",
    createRule: staff,
    updateRule: staff,
    deleteRule: director,
    fields: [
      { name: "fullName", type: "text", required: true, min: 5, max: 120 },
      { name: "phone", type: "text", required: true, min: 10, max: 16 },
      { name: "email", type: "email", required: true },
      {
        name: "user",
        type: "relation",
        required: false,
        collectionId: users.id,
        minSelect: 0,
        maxSelect: 1,
        cascadeDelete: false,
      },
      { name: "deleted", type: "bool" },
    ],
    indexes: ["CREATE UNIQUE INDEX idx_customers_email ON customers (email)"],
  })
  app.save(customers)

  users.fields.add(new Field({
    name: "customer",
    type: "relation",
    required: false,
    collectionId: customers.id,
    minSelect: 0,
    maxSelect: 1,
    cascadeDelete: false,
  }))
  app.save(users)

  const passports = new Collection({
    type: "base",
    name: "passports",
    listRule: staff,
    viewRule: staff,
    createRule: staff,
    updateRule: staff,
    deleteRule: director,
    fields: [
      {
        name: "car",
        type: "relation",
        required: true,
        collectionId: cars.id,
        minSelect: 1,
        maxSelect: 1,
        cascadeDelete: false,
      },
      { name: "number", type: "text", required: true, min: 6, max: 20 },
      { name: "issuedOn", type: "date", required: true },
      { name: "issuedBy", type: "text", required: true, min: 2, max: 120 },
      { name: "deleted", type: "bool" },
    ],
    indexes: ["CREATE UNIQUE INDEX idx_passports_car ON passports (car)"],
  })
  app.save(passports)

  const deals = new Collection({
    type: "base",
    name: "deals",
    listRule: '@request.auth.role = "manager" || @request.auth.role = "director" || customer.user = @request.auth.id',
    viewRule: '@request.auth.role = "manager" || @request.auth.role = "director" || customer.user = @request.auth.id',
    createRule: '@request.auth.role = "manager"',
    updateRule: '@request.auth.role = "manager"',
    deleteRule: director,
    fields: [
      {
        name: "car",
        type: "relation",
        required: true,
        collectionId: cars.id,
        minSelect: 1,
        maxSelect: 1,
        cascadeDelete: false,
      },
      {
        name: "customer",
        type: "relation",
        required: true,
        collectionId: customers.id,
        minSelect: 1,
        maxSelect: 1,
        cascadeDelete: false,
      },
      {
        name: "manager",
        type: "relation",
        required: true,
        collectionId: users.id,
        minSelect: 1,
        maxSelect: 1,
        cascadeDelete: false,
      },
      { name: "basePrice", type: "number", required: true, onlyInt: true, min: 0 },
      { name: "optionsTotal", type: "number", onlyInt: true, min: 0 },
      { name: "discountPercent", type: "number", onlyInt: true, min: 0, max: 25 },
      { name: "automaticPercent", type: "number", onlyInt: true, min: 0, max: 25 },
      { name: "finalPrice", type: "number", required: true, onlyInt: true, min: 0 },
      { name: "note", type: "text", required: false, max: 300 },
      { name: "deleted", type: "bool" },
    ],
  })
  app.save(deals)

  const drives = new Collection({
    type: "base",
    name: "test_drives",
    listRule: staff + " || customer.user = @request.auth.id",
    viewRule: staff + " || customer.user = @request.auth.id",
    createRule: '@request.auth.role = "manager" || (@request.auth.role = "buyer" && @request.body.customer = @request.auth.customer)',
    updateRule: '@request.auth.role = "manager" || customer.user = @request.auth.id',
    deleteRule: director,
    fields: [
      {
        name: "car",
        type: "relation",
        required: true,
        collectionId: cars.id,
        minSelect: 1,
        maxSelect: 1,
        cascadeDelete: false,
      },
      {
        name: "customer",
        type: "relation",
        required: true,
        collectionId: customers.id,
        minSelect: 1,
        maxSelect: 1,
        cascadeDelete: false,
      },
      { name: "startsAt", type: "date", required: true },
      { name: "endsAt", type: "date", required: true },
      {
        name: "status",
        type: "select",
        required: true,
        maxSelect: 1,
        values: ["planned", "done", "cancelled"],
      },
      { name: "deleted", type: "bool" },
    ],
  })
  app.save(drives)

  function save(collection, data) {
    const record = new Record(collection)
    const keys = Object.keys(data)
    for (let i = 0; i < keys.length; i++) {
      record.set(keys[i], data[keys[i]])
    }
    app.save(record)
    return record
  }

  const toyota = save(brands, { name: "Toyota", country: "Япония", deleted: false })
  const bmw = save(brands, { name: "BMW", country: "Германия", deleted: false })
  const hyundai = save(brands, { name: "Hyundai", country: "Корея", deleted: false })
  const camry = save(models, { brand: toyota.id, name: "Camry", bodyType: "sedan", seats: 5, deleted: false })
  const x5 = save(models, { brand: bmw.id, name: "X5", bodyType: "suv", seats: 5, deleted: false })
  const solaris = save(models, { brand: hyundai.id, name: "Solaris", bodyType: "sedan", seats: 5, deleted: false })
  const heat = save(options, { name: "Подогрев сидений", price: 45000, deleted: false })
  const camera = save(options, { name: "Камера заднего вида", price: 35000, deleted: false })
  const leather = save(options, { name: "Кожаный салон", price: 120000, deleted: false })
  const carCamry = save(cars, {
    model: camry.id,
    vin: "JTNBE46K503123456",
    year: 2022,
    price: 3200000,
    mileage: 45000,
    color: "Белый",
    status: "in_stock",
    options: [heat.id, camera.id],
    deleted: false,
  })
  const carX5 = save(cars, {
    model: x5.id,
    vin: "WBAJB1C50JB234567",
    year: 2024,
    price: 8900000,
    mileage: 12000,
    color: "Чёрный",
    status: "in_stock",
    options: [leather.id, camera.id],
    deleted: false,
  })
  const carSolaris = save(cars, {
    model: solaris.id,
    vin: "Z94CT41DBJR345678",
    year: 2018,
    price: 1100000,
    mileage: 140000,
    color: "Серый",
    status: "sold",
    options: [heat.id],
    deleted: false,
  })
  save(passports, {
    car: carCamry.id,
    number: "77УН123456",
    issuedOn: "2022-04-12 00:00:00.000Z",
    issuedBy: "ГИБДД Москвы",
    deleted: false,
  })
  save(passports, {
    car: carX5.id,
    number: "78ОТ654321",
    issuedOn: "2024-02-02 00:00:00.000Z",
    issuedBy: "ГИБДД Санкт-Петербурга",
    deleted: false,
  })
  save(passports, {
    car: carSolaris.id,
    number: "50АА111222",
    issuedOn: "2018-06-01 00:00:00.000Z",
    issuedBy: "ГИБДД Московской области",
    deleted: false,
  })

  const directorUser = save(users, {
    email: "director@salon.local",
    password: "director123",
    fullName: "Орлова Ирина",
    phone: "+79031110001",
    role: "director",
    verified: true,
  })
  const manager = save(users, {
    email: "manager@salon.local",
    password: "manager123",
    fullName: "Кузнецов Артём",
    phone: "+79031110002",
    role: "manager",
    verified: true,
  })
  const buyer = save(users, {
    email: "buyer@salon.local",
    password: "buyer123",
    fullName: "Смирнов Павел",
    phone: "+79031110003",
    role: "buyer",
    verified: true,
  })
  const walkIn = save(customers, {
    fullName: "Иванова Мария",
    phone: "+79032220004",
    email: "ivanova@example.com",
    deleted: false,
  })
  const buyerCustomer = save(customers, {
    fullName: "Смирнов Павел",
    phone: "+79031110003",
    email: "buyer@salon.local",
    user: buyer.id,
    deleted: false,
  })
  buyer.set("customer", buyerCustomer.id)
  app.save(buyer)

  save(deals, {
    car: carSolaris.id,
    customer: walkIn.id,
    manager: manager.id,
    basePrice: 1100000,
    optionsTotal: 45000,
    discountPercent: 0,
    automaticPercent: 8,
    finalPrice: 1053400,
    note: "Скидка за возраст и пробег",
    deleted: false,
  })
  save(drives, {
    car: carCamry.id,
    customer: buyerCustomer.id,
    startsAt: "2026-11-21 12:00:00.000Z",
    endsAt: "2026-11-21 13:00:00.000Z",
    status: "planned",
    deleted: false,
  })

  void directorUser
}, (app) => {
  const names = ["test_drives", "deals", "passports", "customers", "cars", "options", "models", "brands"]
  for (let i = 0; i < names.length; i++) {
    try {
      app.delete(app.findCollectionByNameOrId(names[i]))
    } catch (_) {}
  }
})
