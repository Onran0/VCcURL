## Модуль "curl:curl"

### Предоставляет набор функций для базовой работы с URL адресами, получения информации о установленной версии **curl** и получения информации о текущем состоянии связи с программной частью **API**

Зашифровывает строку с произвольными символами в валидное для URL текст
```lua
function curl.url_encode(str)
```

Расшифровывает валидную для URL строку в текст с проивзольными закодироваными символами
```lua
function curl.url_decode(str)
```

Извлекает протокол из URL адреса
```lua
function curl.get_protocol(url)
```

Добавляет в начало адреса `protocol`:// 
```lua
function curl.use_protocol(protocol, url)
```

Проверяет валидность используемого протокола в URL адресе. Он должен быть равен или `protocol`, или `alt` (если это строка), или любому элементу из `alt` (если это таблица). В противном случае упадёт ошибка
```lua
function curl.check_url_protocol(protocol, url, alt)
```

Возвращает **true**, если программная часть **API** существует в файлах. В противном случае **false**
```lua
function curl.has_program_api()
```

Возвращает **true**, если установить связь с программной частью **API** возможно. В противном случае **false**. Для корректного результата должна вызываться не раньше чем через несколько (обычно 1-3) секунд после вызова события **on_world_open**
```lua
function curl.is_program_api_connectable()
```

### Информация о установленной версии **curl**

Вся информация хранится в таблице `curl.info`

#### curl.info.version
Версия **curl** ввиде строки

#### curl.info.system
Название операционной системы для которой предназначена установленная версия

#### curl.info.release_date
Дата выпуска текущей версии

`curl.info.release_date.readable` - Удобочитаемая дата ввиде строки  
`curl.info.release_date.parts` - Таблица, которая хранит части даты в полях, такие как **year**, **month**, **day**. Каждое из полей представлено ввиде целого числа  
`curl.info.release_date.epoch` - Временная метка в целых миллисекундах  

#### curl.info.protocols
Таблица в которой содержатся все протоколы, поддерживаемые текущей версией **curl**

#### curl.info.features
Таблица в которой содержатся все возможности, поддерживаемые текущей версией **curl**