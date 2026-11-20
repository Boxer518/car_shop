import 'collection_spec.dart';

const statusChoices = [
  Choice('in_stock', 'В наличии'),
  Choice('reserved', 'Бронь'),
  Choice('sold', 'Продан'),
];

const bodyChoices = [
  Choice('sedan', 'Седан'),
  Choice('suv', 'Кроссовер'),
  Choice('hatchback', 'Хэтчбек'),
  Choice('coupe', 'Купе'),
  Choice('wagon', 'Универсал'),
  Choice('van', 'Фургон'),
];

const driveStatusChoices = [
  Choice('planned', 'Запланирован'),
  Choice('done', 'Завершён'),
  Choice('cancelled', 'Отменён'),
];

const roleChoices = [
  Choice('buyer', 'Покупатель'),
  Choice('manager', 'Менеджер'),
  Choice('director', 'Директор'),
];

const brandsSpec = CollectionSpec(
  collection: 'brands',
  path: '/brands',
  title: 'Марки',
  singular: 'Марка',
  defaultSort: 'name',
  searchKeys: ['name', 'country'],
  sorts: [Choice('name', 'Название'), Choice('country', 'Страна')],
  columns: ['name', 'country'],
  filters: [
    FilterSpec(
      key: 'country',
      label: 'Страна',
      kind: FilterKind.contains,
      field: 'country',
    ),
    FilterSpec(
      key: 'name',
      label: 'Название',
      kind: FilterKind.contains,
      field: 'name',
    ),
    FilterSpec(
      key: 'countryExact',
      label: 'Страна точно',
      kind: FilterKind.equals,
      field: 'country',
    ),
  ],
  fields: [
    FieldSpec(
      key: 'name',
      label: 'Название',
      kind: FieldKind.text,
      required: true,
      minLength: 2,
      maxLength: 80,
    ),
    FieldSpec(
      key: 'country',
      label: 'Страна',
      kind: FieldKind.text,
      required: true,
      minLength: 2,
      maxLength: 60,
    ),
  ],
);

const modelsSpec = CollectionSpec(
  collection: 'models',
  path: '/models',
  title: 'Модели',
  singular: 'Модель',
  defaultSort: 'name',
  searchKeys: ['name'],
  sorts: [Choice('name', 'Название'), Choice('seats', 'Мест')],
  columns: ['brand', 'name', 'bodyType', 'seats'],
  filters: [
    FilterSpec(
      key: 'bodyType',
      label: 'Кузов',
      kind: FilterKind.equals,
      field: 'bodyType',
      choices: bodyChoices,
    ),
    FilterSpec(
      key: 'seatsFrom',
      label: 'Мест от',
      kind: FilterKind.min,
      field: 'seats',
    ),
    FilterSpec(
      key: 'brand',
      label: 'Марка',
      kind: FilterKind.relation,
      field: 'brand',
      relation: 'brands',
    ),
  ],
  fields: [
    FieldSpec(
      key: 'brand',
      label: 'Марка',
      kind: FieldKind.relation,
      required: true,
      relation: 'brands',
    ),
    FieldSpec(
      key: 'name',
      label: 'Название',
      kind: FieldKind.text,
      required: true,
      minLength: 1,
      maxLength: 80,
    ),
    FieldSpec(
      key: 'bodyType',
      label: 'Кузов',
      kind: FieldKind.select,
      required: true,
      choices: bodyChoices,
    ),
    FieldSpec(
      key: 'seats',
      label: 'Мест',
      kind: FieldKind.number,
      required: true,
      min: 2,
      max: 9,
    ),
  ],
);

const optionsSpec = CollectionSpec(
  collection: 'options',
  path: '/options',
  title: 'Опции',
  singular: 'Опция',
  defaultSort: 'name',
  searchKeys: ['name'],
  sorts: [Choice('name', 'Название'), Choice('price', 'Цена')],
  columns: ['name', 'price'],
  filters: [
    FilterSpec(
      key: 'name',
      label: 'Название',
      kind: FilterKind.contains,
      field: 'name',
    ),
    FilterSpec(
      key: 'priceFrom',
      label: 'Цена от',
      kind: FilterKind.min,
      field: 'price',
    ),
    FilterSpec(
      key: 'priceTo',
      label: 'Цена до',
      kind: FilterKind.max,
      field: 'price',
    ),
  ],
  fields: [
    FieldSpec(
      key: 'name',
      label: 'Название',
      kind: FieldKind.text,
      required: true,
      minLength: 2,
      maxLength: 80,
    ),
    FieldSpec(
      key: 'price',
      label: 'Цена',
      kind: FieldKind.number,
      required: true,
      min: 0,
      max: 2000000,
    ),
  ],
);

const carsSpec = CollectionSpec(
  collection: 'cars',
  path: '/cars',
  title: 'Автомобили',
  singular: 'Автомобиль',
  defaultSort: 'price',
  searchKeys: ['vin', 'color'],
  sorts: [
    Choice('price', 'Цена'),
    Choice('year', 'Год'),
    Choice('mileage', 'Пробег'),
  ],
  columns: ['vin', 'model', 'year', 'price', 'mileage', 'status'],
  filters: [
    FilterSpec(
      key: 'status',
      label: 'Статус',
      kind: FilterKind.equals,
      field: 'status',
      choices: statusChoices,
    ),
    FilterSpec(
      key: 'yearFrom',
      label: 'Год от',
      kind: FilterKind.min,
      field: 'year',
    ),
    FilterSpec(
      key: 'priceTo',
      label: 'Цена до',
      kind: FilterKind.max,
      field: 'price',
    ),
  ],
  fields: [
    FieldSpec(
      key: 'model',
      label: 'Модель',
      kind: FieldKind.relation,
      required: true,
      relation: 'models',
    ),
    FieldSpec(
      key: 'vin',
      label: 'VIN',
      kind: FieldKind.vin,
      required: true,
      minLength: 17,
      maxLength: 17,
    ),
    FieldSpec(
      key: 'year',
      label: 'Год',
      kind: FieldKind.number,
      required: true,
      min: 1990,
      max: 2026,
    ),
    FieldSpec(
      key: 'price',
      label: 'Цена',
      kind: FieldKind.number,
      required: true,
      min: 100000,
      max: 50000000,
    ),
    FieldSpec(
      key: 'mileage',
      label: 'Пробег',
      kind: FieldKind.number,
      required: true,
      min: 0,
      max: 1000000,
    ),
    FieldSpec(
      key: 'color',
      label: 'Цвет',
      kind: FieldKind.text,
      required: true,
      minLength: 2,
      maxLength: 40,
    ),
    FieldSpec(
      key: 'status',
      label: 'Статус',
      kind: FieldKind.select,
      required: true,
      choices: statusChoices,
    ),
    FieldSpec(
      key: 'options',
      label: 'Опции',
      kind: FieldKind.multi,
      relation: 'options',
    ),
  ],
);

const customersSpec = CollectionSpec(
  collection: 'customers',
  path: '/customers',
  title: 'Клиенты',
  singular: 'Клиент',
  defaultSort: 'fullName',
  searchKeys: ['fullName', 'phone', 'email'],
  sorts: [Choice('fullName', 'Имя'), Choice('email', 'Email')],
  columns: ['fullName', 'phone', 'email'],
  filters: [
    FilterSpec(
      key: 'phone',
      label: 'Телефон',
      kind: FilterKind.contains,
      field: 'phone',
    ),
    FilterSpec(
      key: 'email',
      label: 'Email',
      kind: FilterKind.contains,
      field: 'email',
    ),
    FilterSpec(
      key: 'fullName',
      label: 'Имя',
      kind: FilterKind.contains,
      field: 'fullName',
    ),
  ],
  fields: [
    FieldSpec(
      key: 'fullName',
      label: 'ФИО',
      kind: FieldKind.text,
      required: true,
      minLength: 5,
      maxLength: 120,
    ),
    FieldSpec(
      key: 'phone',
      label: 'Телефон',
      kind: FieldKind.phone,
      required: true,
      minLength: 10,
      maxLength: 16,
    ),
    FieldSpec(
      key: 'email',
      label: 'Email',
      kind: FieldKind.email,
      required: true,
    ),
  ],
);

const passportsSpec = CollectionSpec(
  collection: 'passports',
  path: '/passports',
  title: 'ПТС',
  singular: 'ПТС',
  defaultSort: 'number',
  searchKeys: ['number', 'issuedBy'],
  sorts: [Choice('number', 'Номер'), Choice('issuedOn', 'Дата')],
  columns: ['number', 'car', 'issuedOn', 'issuedBy'],
  filters: [
    FilterSpec(
      key: 'number',
      label: 'Номер',
      kind: FilterKind.contains,
      field: 'number',
    ),
    FilterSpec(
      key: 'issuedBy',
      label: 'Кем выдан',
      kind: FilterKind.contains,
      field: 'issuedBy',
    ),
    FilterSpec(
      key: 'car',
      label: 'Автомобиль',
      kind: FilterKind.relation,
      field: 'car',
      relation: 'cars',
    ),
  ],
  fields: [
    FieldSpec(
      key: 'car',
      label: 'Автомобиль',
      kind: FieldKind.relation,
      required: true,
      relation: 'cars',
    ),
    FieldSpec(
      key: 'number',
      label: 'Номер',
      kind: FieldKind.text,
      required: true,
      minLength: 6,
      maxLength: 20,
    ),
    FieldSpec(
      key: 'issuedOn',
      label: 'Дата выдачи',
      kind: FieldKind.date,
      required: true,
    ),
    FieldSpec(
      key: 'issuedBy',
      label: 'Кем выдан',
      kind: FieldKind.text,
      required: true,
      minLength: 2,
      maxLength: 120,
    ),
  ],
);

const dealsSpec = CollectionSpec(
  collection: 'deals',
  path: '/deals',
  title: 'Сделки',
  singular: 'Сделка',
  defaultSort: 'finalPrice',
  searchKeys: ['note'],
  sorts: [Choice('finalPrice', 'Итог'), Choice('discountPercent', 'Скидка')],
  columns: ['car', 'customer', 'discountPercent', 'finalPrice'],
  filters: [
    FilterSpec(
      key: 'customer',
      label: 'Клиент',
      kind: FilterKind.relation,
      field: 'customer',
      relation: 'customers',
    ),
    FilterSpec(
      key: 'discountFrom',
      label: 'Скидка от',
      kind: FilterKind.min,
      field: 'discountPercent',
    ),
    FilterSpec(
      key: 'note',
      label: 'Примечание',
      kind: FilterKind.contains,
      field: 'note',
    ),
  ],
  deal: true,
  fields: [
    FieldSpec(
      key: 'car',
      label: 'Автомобиль',
      kind: FieldKind.relation,
      required: true,
      relation: 'cars',
    ),
    FieldSpec(
      key: 'customer',
      label: 'Клиент',
      kind: FieldKind.relation,
      required: true,
      relation: 'customers',
    ),
    FieldSpec(
      key: 'discountPercent',
      label: 'Скидка менеджера, %',
      kind: FieldKind.number,
      min: 0,
      max: 25,
    ),
    FieldSpec(
      key: 'note',
      label: 'Примечание',
      kind: FieldKind.longText,
      maxLength: 300,
    ),
    FieldSpec(
      key: 'basePrice',
      label: 'Цена автомобиля',
      kind: FieldKind.number,
      computed: true,
    ),
    FieldSpec(
      key: 'optionsTotal',
      label: 'Опции',
      kind: FieldKind.number,
      computed: true,
    ),
    FieldSpec(
      key: 'automaticPercent',
      label: 'Автоскидка, %',
      kind: FieldKind.number,
      computed: true,
    ),
    FieldSpec(
      key: 'finalPrice',
      label: 'Итог',
      kind: FieldKind.number,
      computed: true,
    ),
  ],
);

const drivesSpec = CollectionSpec(
  collection: 'test_drives',
  path: '/drives',
  title: 'Тест-драйвы',
  singular: 'Тест-драйв',
  defaultSort: 'startsAt',
  searchKeys: ['status'],
  sorts: [Choice('startsAt', 'Начало'), Choice('status', 'Статус')],
  columns: ['car', 'customer', 'startsAt', 'endsAt', 'status'],
  filters: [
    FilterSpec(
      key: 'status',
      label: 'Статус',
      kind: FilterKind.equals,
      field: 'status',
      choices: driveStatusChoices,
    ),
    FilterSpec(
      key: 'car',
      label: 'Автомобиль',
      kind: FilterKind.relation,
      field: 'car',
      relation: 'cars',
    ),
    FilterSpec(
      key: 'customer',
      label: 'Клиент',
      kind: FilterKind.relation,
      field: 'customer',
      relation: 'customers',
    ),
  ],
  drive: true,
  fields: [
    FieldSpec(
      key: 'car',
      label: 'Автомобиль',
      kind: FieldKind.relation,
      required: true,
      relation: 'cars',
    ),
    FieldSpec(
      key: 'customer',
      label: 'Клиент',
      kind: FieldKind.relation,
      required: true,
      relation: 'customers',
    ),
    FieldSpec(
      key: 'startsAt',
      label: 'Начало',
      kind: FieldKind.dateTime,
      required: true,
    ),
    FieldSpec(
      key: 'endsAt',
      label: 'Окончание',
      kind: FieldKind.dateTime,
      required: true,
    ),
    FieldSpec(
      key: 'status',
      label: 'Статус',
      kind: FieldKind.select,
      required: true,
      choices: driveStatusChoices,
    ),
  ],
);

const myDrivesSpec = CollectionSpec(
  collection: 'test_drives',
  path: '/my-drives',
  title: 'Мои записи',
  singular: 'Запись на тест-драйв',
  defaultSort: 'startsAt',
  searchKeys: ['status'],
  sorts: [Choice('startsAt', 'Начало'), Choice('status', 'Статус')],
  columns: ['car', 'startsAt', 'endsAt', 'status'],
  filters: [
    FilterSpec(
      key: 'status',
      label: 'Статус',
      kind: FilterKind.equals,
      field: 'status',
      choices: driveStatusChoices,
    ),
    FilterSpec(
      key: 'car',
      label: 'Автомобиль',
      kind: FilterKind.relation,
      field: 'car',
      relation: 'cars',
    ),
    FilterSpec(
      key: 'startsFrom',
      label: 'Начало содержит',
      kind: FilterKind.contains,
      field: 'startsAt',
    ),
  ],
  lockCustomer: true,
  drive: true,
  fields: [
    FieldSpec(
      key: 'car',
      label: 'Автомобиль',
      kind: FieldKind.relation,
      required: true,
      relation: 'cars',
    ),
    FieldSpec(
      key: 'customer',
      label: 'Клиент',
      kind: FieldKind.relation,
      required: true,
      relation: 'customers',
      hidden: true,
    ),
    FieldSpec(
      key: 'startsAt',
      label: 'Начало',
      kind: FieldKind.dateTime,
      required: true,
    ),
    FieldSpec(
      key: 'endsAt',
      label: 'Окончание',
      kind: FieldKind.dateTime,
      required: true,
    ),
    FieldSpec(
      key: 'status',
      label: 'Статус',
      kind: FieldKind.select,
      required: true,
      choices: driveStatusChoices,
    ),
  ],
);

const catalogSpecs = <CollectionSpec>[
  carsSpec,
  brandsSpec,
  modelsSpec,
  optionsSpec,
  customersSpec,
  passportsSpec,
  dealsSpec,
  drivesSpec,
  myDrivesSpec,
];

CollectionSpec? specByPath(String path) {
  for (final spec in catalogSpecs) {
    if (path == spec.path || path.startsWith('${spec.path}/')) {
      return spec;
    }
  }
  return null;
}

String choiceLabel(List<Choice> choices, String value) {
  for (final choice in choices) {
    if (choice.value == value) {
      return choice.label;
    }
  }
  return value;
}

String recordLabel(String collection, Map<String, dynamic> row) {
  return switch (collection) {
    'brands' || 'models' || 'options' => '${row['name'] ?? row['id']}',
    'cars' => '${row['vin'] ?? row['id']}',
    'customers' => '${row['fullName'] ?? row['id']}',
    'users' => '${row['fullName'] ?? row['email'] ?? row['id']}',
    'passports' => '${row['number'] ?? row['id']}',
    _ => '${row['id'] ?? ''}',
  };
}
