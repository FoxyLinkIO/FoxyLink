## Материалы доклада (Хакатон по 1C "iS THiS DESiGN" Москва, 16-17 мая 2019)

### Подготовка к мастер класу Elasticsearch

Для всех, кто участвует в хакатоне и планирует посетить мой мастер класс, необходимо установить **Elasticsearch**. 
<BR>
Что бы избежать множества проблем, хочу предложить воспользоваться [облачным **Elasticsearch**](https://www.elastic.co/cloud). Регистрация очень простая и предоставляется возможность получить бесплатный доступ на 14 дней.

<h4 align="center">Регистрация в облаке</h3>
<p align="center">
  <a href="https://www.elastic.co/cloud">
    <img src="https://raw.githubusercontent.com/FoxyLinkIO/FoxyLink/develop/img/is-this-design-2019/cloud-trial.png" alt="" width=549 height=300>
  </a>
</p>
<h4 align="center">Подтвердите регистрацию</h3>
<p align="center">    
  <a href="https://cloud.elastic.co/">
    <img src="https://raw.githubusercontent.com/FoxyLinkIO/FoxyLink/develop/img/is-this-design-2019/email-confirm.png" alt="" width=506 height=600>
  </a>
</p>
<h4 align="center">Нажмите <i>Create deployment</i> и создайте машинку по умолчанию</h3>
<p align="center">    
  <a href="https://cloud.elastic.co/">
    <img src="https://raw.githubusercontent.com/FoxyLinkIO/FoxyLink/develop/img/is-this-design-2019/14-day-trial-deployment.png" alt="" width=662 height=400>
  </a>
</p>
<h4 align="center">Измените пароль и запишите его</h3>
<p align="center">    
  <a href="https://cloud.elastic.co/">
    <img src="https://raw.githubusercontent.com/FoxyLinkIO/FoxyLink/develop/img/is-this-design-2019/reseting-password.png" alt="" width=933 height=400>
  </a>
</p>

Так же необходимо:
- REST клиент, например: [Fiddler](https://www.telerik.com/fiddler) или [Advanced REST client](https://chrome.google.com/webstore/detail/advanced-rest-client/hgmloofddffdnphfgcellkdfbfbjeloo) или другой;     
- «1С: Предприятие 8» версия от 8.3.11.2924 и выше;
- Демо-конфигурация с режимом совместимости: **8.3.11** и выше.

#

**Elasticsearch** — отлично масштабируемая система полнотекстового поиска и анализа данных с открытым исходным кодом. Позволяет хранить, искать и анализировать большие объемы данных практически в режиме реального времени.  

# Примеры использования 

- Интернет-магазин, где есть функция поиска товаров. В этом случае можно использовать **Elasticsearch** для хранения всего каталога номенклатуры, а также для поиска и автоматического дополнения при вводе текста; 
- Сбор данных журнала регистрации 1С в **ElasticSearch**, а также их последующий анализ для поиска тенденций, сбора статистики и выявления аномалий https://infostart.ru/public/545895/;  
- Оповещения о различных событиях, на которые пользователи подписались, с помощью функции reverse-search (Percolator);  
- История изменений объектов информационной базы https://infostart.ru/public/338416/; 
- Построение системы бизнес-аналитики, но пока существенно проигрывает **MS Power BI**. 

Многим известно, что полнотекстовый поиск от фирмы 1С, возможно, удовлетворяет скоростью работы (индексации, доступности к поиску, поиску) на базах данных до 5GB, но с увеличением размера полнотекстовый поиск «ломается».

# Базовые понятия и описание API интерфейса

Для создания Authorization заголовка воспользуемся сервисом https://www.blitter.se/utils/basic-authentication-header-generator/

**Индекс** — набор документов, справочников или объектов, которые имеют схожие характеристики.  
**Документ** — базовая единица информации, которая может быть проиндексирована.

### Cluster Health
базовая проверка кластера **Elasticsearch**. Для выполнения проверки необходимо выполнить такую команду: `GET /_cat/health?v` 

```csharp
---------------------------------------------------------------------- 

BeginRequest: 01.05.2019 8:59:01 
 
REQUEST URL 
Host URL: elastic.aws.cloud.es.io 
Resource: GET /_cat/health?v 
 
RESPONSE BODY  
Result: 200 
[{
	"epoch": "1557478590",
	"timestamp": "08:56:30",
	"cluster": "85ab6af401794b28a33b2b655168c296",
	"status": "green",
	"node.total": "3",
	"node.data": "2",
	"shards": "8",
	"pri": "4",
	"relo": "0",
	"init": "0",
	"unassign": "0",
	"pending_tasks": "0",
	"max_task_wait_time": "-",
	"active_shards_percent": "100.0%"
}] 
 
DoneResponse: 01.05.2019 8:59:02 
Overall Elapsed: 250 ms 
---------------------------------------------------------------------- 
```

### [cat APIs](https://www.elastic.co/guide/en/elasticsearch/reference/7.0/cat.html) 
Интерфейс (`/_cat`), который предназначен для форматирования вывода и получения справки. Может принимать параметр `help`. Например, такой вызов: `GET /_cat/health?help` 

```csharp
---------------------------------------------------------------------- 
BeginRequest: 01.05.2019 10:28:15

REQUEST URL
Host URL: elastic.aws.cloud.es.io
Resource: GET /_cat/health?help

RESPONSE BODY 
Result: 200
epoch                 | t,time                                   | seconds since 1970-01-01 00:00:00  
timestamp             | ts,hms,hhmmss                            | time in HH:MM:SS                   
cluster               | cl                                       | cluster name                       
status                | st                                       | health status                      
node.total            | nt,nodeTotal                             | total number of nodes              
node.data             | nd,nodeData                              | number of nodes that can store data
shards                | t,sh,shards.total,shardsTotal            | total number of shards             
pri                   | p,shards.primary,shardsPrimary           | number of primary shards           
relo                  | r,shards.relocating,shardsRelocating     | number of relocating nodes         
init                  | i,shards.initializing,shardsInitializing | number of initializing nodes       
unassign              | u,shards.unassigned,shardsUnassigned     | number of unassigned shards        
pending_tasks         | pt,pendingTasks                          | number of pending tasks            
max_task_wait_time    | mtwt,maxTaskWaitTime                     | wait time of longest task pending  
active_shards_percent | asp,activeShardsPercent                  | active number of shards in percent 


DoneResponse: 01.05.2019 10:28:16
Overall Elapsed: 636 ms
---------------------------------------------------------------------- 
```

### Индексы

#### Показать все индексы: `GET /_cat/indices?v` 
```csharp
----------------------------------------------------------------------
BeginRequest: 01.05.2019 10:53:04

REQUEST URL
Host URL: 85ab6af401794b28a33b2b655168c296.eu-central-1.aws.cloud.es.io
Resource: GET /_cat/indices?v

RESPONSE BODY 
Result: 200
[{
	"health": "green",
	"status": "open",
	"index": ".kibana_task_manager",
	"uuid": "sS7HyDzRRXuEi798otq49g",
	"pri": "1",
	"rep": "1",
	"docs.count": "2",
	"docs.deleted": "0",
	"store.size": "42.4kb",
	"pri.store.size": "12.8kb"
}, {
	"health": "green",
	"status": "open",
	"index": ".security-7",
	"uuid": "xS8E0RmeS-qnr6ct4sdCjA",
	"pri": "1",
	"rep": "1",
	"docs.count": "4",
	"docs.deleted": "0",
	"store.size": "70.9kb",
	"pri.store.size": "35.4kb"
}, {
	"health": "green",
	"status": "open",
	"index": ".kibana_1",
	"uuid": "zSpMef6xRS-ac-RytsPkLA",
	"pri": "1",
	"rep": "1",
	"docs.count": "2",
	"docs.deleted": "0",
	"store.size": "21.4kb",
	"pri.store.size": "10.7kb"
}, {
	"health": "green",
	"status": "open",
	"index": "apm-7.0.1-onboarding-2019.05.09",
	"uuid": "Po1m-DblTBaX0DhbfqpjIw",
	"pri": "1",
	"rep": "1",
	"docs.count": "1",
	"docs.deleted": "0",
	"store.size": "12.6kb",
	"pri.store.size": "6.3kb"
}]

DoneResponse: 01.05.2019 10:53:06
Overall Elapsed: 2 033 ms
---------------------------------------------------------------------- 
```

#### cat API: `GET /_cat/indices?help` 
```csharp
----------------------------------------------------------------------
BeginRequest: 01.05.2019 11:04:00

REQUEST URL
Host URL: elastic.aws.cloud.es.io
Resource: GET /_cat/indices?help

RESPONSE BODY 
Result: 200
health                           | h                              | current health status                                               
status                           | s                              | open/close status 

...

search.throttled                 | sth                            | indicates if the index is search throttled                           

DoneResponse: 01.05.2019 11:04:02
Overall Elapsed: 1 661 ms
---------------------------------------------------------------------- 
```

#### Создание индекса: `PUT /product?pretty`
```csharp
----------------------------------------------------------------------
BeginRequest: 01.05.2019 11:10:34

REQUEST URL
Host URL: elastic.aws.cloud.es.io
Resource: PUT /product?pretty

REQUEST BODY


RESPONSE BODY
Result: 200
{
  "acknowledged" : true,
  "shards_acknowledged" : true,
  "index" : "product"
}


DoneResponse: 01.05.2019 11:10:34
Overall Elapsed: 609 ms
----------------------------------------------------------------------
```

```csharp
----------------------------------------------------------------------
BeginRequest: 01.05.2019 11:11:52

REQUEST URL
Host URL: elastic.aws.cloud.es.io
Resource: GET /_cat/indices?v

RESPONSE BODY 
Result: 200
[{
	"health": "green",
	"status": "open",
	"index": "product",
	"uuid": "MWuP4T5BR6WjHzi4-dq_uw",
	"pri": "1",
	"rep": "1",
	"docs.count": "0",
	"docs.deleted": "0",
	"store.size": "460b",
	"pri.store.size": "230b"
}]

DoneResponse: 01.05.2019 11:11:52
Overall Elapsed: 378 ms
----------------------------------------------------------------------
```

#### Удаление индекса `DELETE /product?pretty`
```csharp
----------------------------------------------------------------------
BeginRequest: 01.05.2019 11:27:52

REQUEST URL
Host URL: elastic.aws.cloud.es.io
Resource: DELETE /product?pretty

RESPONSE BODY 
Result: 200
{
  "acknowledged" : true
}


DoneResponse: 01.05.2019 11:27:53
Overall Elapsed: 455 ms
----------------------------------------------------------------------
```

#### Добавление документа в индекс `PUT /product/_doc/1?pretty`
```csharp
----------------------------------------------------------------------
BeginRequest: 01.05.2019 11:20:35

REQUEST URL
Host URL: elastic.aws.cloud.es.io
Resource: PUT /product/_doc/1?pretty

REQUEST BODY
{
  "name": "Методическое пособие релиз-инженера 1С и не только"
}

RESPONSE BODY
Result: 201
{
  "_index" : "product",
  "_type" : "_doc",
  "_id" : "1",
  "_version" : 1,
  "result" : "created",
  "_shards" : {
    "total" : 2,
    "successful" : 2,
    "failed" : 0
  },
  "_seq_no" : 0,
  "_primary_term" : 1
}


DoneResponse: 01.05.2019 11:20:35
Overall Elapsed: 749 ms
----------------------------------------------------------------------
```
Если вызвать еще раз команду `PUT /product/_doc/1?pretty`, но с измененными данными, элемент индекса будет переидексирован, а так же будут изменены значения `_seq_no` и `_version`. 

#### Чтение документа из индекса `GET /product/_doc/1?pretty`
```csharp
----------------------------------------------------------------------
BeginRequest: 01.05.2019 11:24:35

REQUEST URL
Host URL: elastic.aws.cloud.es.io
Resource: GET /product/_doc/1?pretty

RESPONSE BODY 
Result: 200
{
  "_index" : "product",
  "_type" : "_doc",
  "_id" : "1",
  "_version" : 1,
  "_seq_no" : 0,
  "_primary_term" : 1,
  "found" : true,
  "_source" : {
    "name" : "Методическое пособие релиз-инженера 1С и не только"
  }
}


DoneResponse: 01.05.2019 11:24:35
Overall Elapsed: 134 ms
----------------------------------------------------------------------
```

#### Добавление документа в индекс без указания `_id` `POST /product/_doc?pretty`
```csharp
----------------------------------------------------------------------
BeginRequest: 01.05.2019 11:39:58

REQUEST URL
Host URL: elastic.aws.cloud.es.io
Resource: POST /product/_doc?pretty

REQUEST BODY
{
  "name": "Методическое пособие релиз-инженера 1С и не только!"
}

RESPONSE BODY
Result: 201
{
  "_index" : "product",
  "_type" : "_doc",
  "_id" : "1qeKoWoB7PqJYpX13xYJ",
  "_version" : 1,
  "result" : "created",
  "_shards" : {
    "total" : 2,
    "successful" : 2,
    "failed" : 0
  },
  "_seq_no" : 3,
  "_primary_term" : 1
}


DoneResponse: 01.05.2019 11:39:59
Overall Elapsed: 1 039 ms
----------------------------------------------------------------------
```

#### Обновление документа в индексе `POST /product/_update/1?pretty`
На самом деле, Elasticsearch не обновляет индекс, а удаляет старый документ из индекса и индексирует новый (добавляемый) документ.
```csharp
----------------------------------------------------------------------
BeginRequest: 01.05.2019 11:50:35

REQUEST URL
Host URL: elastic.aws.cloud.es.io
Resource: POST /product/_update/1?pretty

REQUEST BODY
{
  "doc": {
    "name": "Методическое пособие релиз-инженера 1С и не только!!!"
  }
}

RESPONSE BODY
Result: 200
{
  "_index" : "product",
  "_type" : "_doc",
  "_id" : "1",
  "_version" : 4,
  "result" : "updated",
  "_shards" : {
    "total" : 2,
    "successful" : 2,
    "failed" : 0
  },
  "_seq_no" : 4,
  "_primary_term" : 1
}


DoneResponse: 01.05.2019 11:50:36
Overall Elapsed: 653 ms
----------------------------------------------------------------------
```

```csharp
----------------------------------------------------------------------
BeginRequest: 01.05.2019 11:51:25

REQUEST URL
Host URL: elastic.aws.cloud.es.io
Resource: GET /product/_doc/1?pretty

RESPONSE BODY 
Result: 200
{
  "_index" : "product",
  "_type" : "_doc",
  "_id" : "1",
  "_version" : 4,
  "_seq_no" : 4,
  "_primary_term" : 1,
  "found" : true,
  "_source" : {
    "name" : "Методическое пособие релиз-инженера 1С и не только!!!"
  }
}


DoneResponse: 01.05.2019 11:51:25
Overall Elapsed: 509 ms
----------------------------------------------------------------------
```

#### Удаление документа из индекса `DELETE /product/_doc/1qeKoWoB7PqJYpX13xYJ?pretty`
```csharp
----------------------------------------------------------------------
BeginRequest: 01.05.2019 11:55:14

REQUEST URL
Host URL: elastic.aws.cloud.es.io
Resource: DELETE /product/_doc/1qeKoWoB7PqJYpX13xYJ?pretty

RESPONSE BODY 
Result: 200
{
  "_index" : "product",
  "_type" : "_doc",
  "_id" : "1qeKoWoB7PqJYpX13xYJ",
  "_version" : 2,
  "result" : "deleted",
  "_shards" : {
    "total" : 2,
    "successful" : 2,
    "failed" : 0
  },
  "_seq_no" : 5,
  "_primary_term" : 1
}


DoneResponse: 01.05.2019 11:55:15
Overall Elapsed: 1 064 ms
----------------------------------------------------------------------
```

### Поисковый API `GET /product/_search`
Есть два базовых варианта поискового API: 
- поиск с помощью отправки параметров через REST URI string (RFC 3986);
- второй передача поиского запроса в формате **JSON** в теле запроса.

```csharp
----------------------------------------------------------------------
BeginRequest: 01.05.2019 12:08:22

REQUEST URL
Host URL: elastic.aws.cloud.es.io
Resource: POST /product/_search

REQUEST BODY
{
	"query": {
		"match_all": {}
	}
}

RESPONSE BODY
Result: 200
{
	"took": 2,
	"timed_out": false,
	"_shards": {
		"total": 1,
		"successful": 1,
		"skipped": 0,
		"failed": 0
	},
	"hits": {
		"total": {
			"value": 1,
			"relation": "eq"
		},
		"max_score": 1.0,
		"hits": [{
			"_index": "product",
			"_type": "_doc",
			"_id": "1",
			"_score": 1.0,
			"_source": {
				"name": "Методическое пособие релиз-инженера 1С и не только!!!"
			}
		}]
	}
}

DoneResponse: 01.05.2019 12:08:22
Overall Elapsed: 126 ms
----------------------------------------------------------------------
```

**Elasticsearch** предоставляет собой полный предметно-ориентированный язык запросов, который основан на **JSON**. 
- `query` — содержит описание запроса
  - `match_all` — указывает что необходимо найти все документы в указанном индексе 
  
Ограничение вывобрки запроса:
- `size` — ограничивает количество получаемых результатов. Если параметр не указан, по-умолчанию, будет выведено только 10 результатов.
```csharp
----------------------------------------------------------------------
BeginRequest: 01.05.2019 12:22:47

REQUEST URL
Host URL: elastic.aws.cloud.es.io
Resource: POST /product/_search

REQUEST BODY
{
    "query": {
        "match_all": {}
    },
    "size": 0
}

RESPONSE BODY
Result: 200
{
	"took": 2,
	"timed_out": false,
	"_shards": {
		"total": 1,
		"successful": 1,
		"skipped": 0,
		"failed": 0
	},
	"hits": {
		"total": {
			"value": 1,
			"relation": "eq"
		},
		"max_score": null,
		"hits": []
	}
}

DoneResponse: 01.05.2019 12:22:47
Overall Elapsed: 117 ms
----------------------------------------------------------------------
```

- `from` — параметр необходим для организации получения результатов не с первого совпадения, или для пагинации.
```csharp
----------------------------------------------------------------------
BeginRequest: 01.05.2019 12:38:46

REQUEST URL
Host URL: elastic.aws.cloud.es.io
Resource: POST /product/_search

REQUEST BODY
{
    "query": {
        "match_all": {}
    },
    "from": 1,
    "size": 1,
    "sort": { "_id": "asc"}
}

RESPONSE BODY
Result: 200
{
	"took": 3,
	"timed_out": false,
	"_shards": {
		"total": 1,
		"successful": 1,
		"skipped": 0,
		"failed": 0
	},
	"hits": {
		"total": {
			"value": 2,
			"relation": "eq"
		},
		"max_score": null,
		"hits": [{
			"_index": "product",
			"_type": "_doc",
			"_id": "2",
			"_score": null,
			"_source": {
				"name": "Книга об Elasticsearch"
			},
			"sort": ["2"]
		}]
	}
}

DoneResponse: 01.05.2019 12:38:46
Overall Elapsed: 148 ms
----------------------------------------------------------------------
```

- `sort` — необходим для сортировки результатов запроса.

### Множественная вставка документов в индекс BULK API `POST /product/_bulk?pretty` 
```csharp
----------------------------------------------------------------------
BeginRequest: 02.05.2019 7:38:14

REQUEST URL
Host URL: elastic.aws.cloud.es.io
Resource: POST /product/_bulk?pretty

REQUEST BODY
{"index":{"_id":"1"}}
{"name": "Методическое пособие релиз-инженера 1С и не только" }
{"index":{"_id":"2"}}
{"name": "Книга об Elasticsearch" }


RESPONSE BODY
Result: 200
{
  "took" : 71,
  "errors" : false,
  "items" : [
    {
      "index" : {
        "_index" : "product",
        "_type" : "_doc",
        "_id" : "1",
        "_version" : 2,
        "result" : "updated",
        "_shards" : {
          "total" : 2,
          "successful" : 2,
          "failed" : 0
        },
        "_seq_no" : 1000,
        "_primary_term" : 1,
        "status" : 200
      }
    },
    {
      "index" : {
        "_index" : "product",
        "_type" : "_doc",
        "_id" : "2",
        "_version" : 2,
        "result" : "updated",
        "_shards" : {
          "total" : 2,
          "successful" : 2,
          "failed" : 0
        },
        "_seq_no" : 1001,
        "_primary_term" : 1,
        "status" : 200
      }
    }
  ]
}


DoneResponse: 02.05.2019 7:38:15
Overall Elapsed: 577 ms
----------------------------------------------------------------------
```

### Продолжаем изучать поисковый API `GET /product/_search`
```csharp
{
  "size": 1000,
  "query": {
    "simple_query_string": {
      "query": "dell i9 32gb",
      "default_operator": "and",
      "fields": [
        "Code",
	"Description",
        "FullName",
        "FullName.ngram",
        "Name",
        "Name.ngram",
        "Sku",
        "Sku.keyword",
        "Код"
      ]
    }
  },
  "_source": [
    "Код"
  ]
}
```

- `_source` — предназначен для возврата только указаных полей документа из индекса поиска.
- ` query_string` — строка запроса Lucene, позволяющий задавать условия AND | OR | NOT и поиск по нескольким полям в одной строке запроса. Для пользователей экспертов.
- `simple_query_string` — простая и надежная версия синтаксиса `query_string`.   
- `fields` — поля, где будет происходит поиск, по умолчанию количество ограничено 1024 полями.
- `default_operator` — оператор который будет использован по умолчанию. Например, `dell i9 32gb` =>  `dell AND i9 AND 32gb`

Со всем множеством команд можно ознакомится в [документации](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-request-body.html)

### Описание индекса `GET /product`
```csharp
----------------------------------------------------------------------
BeginRequest: 02.05.2019 16:15:44

REQUEST URL
Host URL: elastic.aws.cloud.es.io
Resource: GET /product

RESPONSE BODY 
Result: 200
{
  "product": {
    "aliases": {},
    "mappings": {
      "properties": {
        "name": {
          "type": "text",
          "fields": {
            "keyword": {
              "type": "keyword",
              "ignore_above": 256
            }
          }
        }
      }
    },
    "settings": {
      "index": {
        "creation_date": "1557591233426",
        "number_of_shards": "1",
        "number_of_replicas": "1",
        "uuid": "X-08F5S7R3yhMliDaNpizQ",
        "version": {
          "created": "7000199"
        },
        "provided_name": "product"
      }
    }
  }
}

DoneResponse: 02.05.2019 16:15:45
Overall Elapsed: 121 ms
----------------------------------------------------------------------
```

### [Analysis](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-analyzers.html)
Процесс преобразования текста в токены или термины, которые добавляются в инвертированный индекс для поиска.
```csharp
PUT product
{
  "mappings": {
    "properties": {
      "name": {
        "type":     "text",
        "analyzer": "standard"
      }
    }
  }
}
```

### Standard Analyzer

```csharp
----------------------------------------------------------------------
BeginRequest: 03.05.2019 3:23:30

REQUEST URL
Host URL: elastic.aws.cloud.es.io
Resource: POST _analyze

REQUEST BODY
{
  "analyzer": "standard",
  "text": "Методическое пособие релиз-инженера 1С и не только"
}

RESPONSE BODY
Result: 200
{
	"tokens": [{
		"token": "методическое",
		"start_offset": 0,
		"end_offset": 12,
		"type": "<ALPHANUM>",
		"position": 0
	}, {
		"token": "пособие",
		"start_offset": 13,
		"end_offset": 20,
		"type": "<ALPHANUM>",
		"position": 1
	}, {
		"token": "релиз",
		"start_offset": 21,
		"end_offset": 26,
		"type": "<ALPHANUM>",
		"position": 2
	}, {
		"token": "инженера",
		"start_offset": 27,
		"end_offset": 35,
		"type": "<ALPHANUM>",
		"position": 3
	}, {
		"token": "1с",
		"start_offset": 36,
		"end_offset": 38,
		"type": "<ALPHANUM>",
		"position": 4
	}, {
		"token": "и",
		"start_offset": 39,
		"end_offset": 40,
		"type": "<ALPHANUM>",
		"position": 5
	}, {
		"token": "не",
		"start_offset": 41,
		"end_offset": 43,
		"type": "<ALPHANUM>",
		"position": 6
	}, {
		"token": "только",
		"start_offset": 44,
		"end_offset": 50,
		"type": "<ALPHANUM>",
		"position": 7
	}]
}

DoneResponse: 03.05.2019 3:23:30
Overall Elapsed: 818 ms
----------------------------------------------------------------------
```

### Simple Analyzer

```csharp
----------------------------------------------------------------------
BeginRequest: 03.05.2019 3:23:30

REQUEST URL
Host URL: elastic.aws.cloud.es.io
Resource: POST _analyze

REQUEST BODY
{
  "analyzer": "simple",
  "text": "Методическое пособие релиз-инженера 1С и не только"
}

RESPONSE BODY
Result: 200
{
	"tokens": [{
		"token": "методическое",
		"start_offset": 0,
		"end_offset": 12,
		"type": "word",
		"position": 0
	}, {
		"token": "пособие",
		"start_offset": 13,
		"end_offset": 20,
		"type": "word",
		"position": 1
	}, {
		"token": "релиз",
		"start_offset": 21,
		"end_offset": 26,
		"type": "word",
		"position": 2
	}, {
		"token": "инженера",
		"start_offset": 27,
		"end_offset": 35,
		"type": "word",
		"position": 3
	}, {
		"token": "с",
		"start_offset": 37,
		"end_offset": 38,
		"type": "word",
		"position": 4
	}, {
		"token": "и",
		"start_offset": 39,
		"end_offset": 40,
		"type": "word",
		"position": 5
	}, {
		"token": "не",
		"start_offset": 41,
		"end_offset": 43,
		"type": "word",
		"position": 6
	}, {
		"token": "только",
		"start_offset": 44,
		"end_offset": 50,
		"type": "word",
		"position": 7
	}]
}

DoneResponse: 03.05.2019 3:23:30
Overall Elapsed: 818 ms
----------------------------------------------------------------------
```

### Custom Analyzer

```csharp
PUT product
{
  "settings": {
    "analysis": {
      "analyzer": {
        "my_custom_analyzer": {
          "type":      "custom", 
          "tokenizer": "ngram",
          "char_filter": [
            "html_strip"
          ],
          "filter": [
            "lowercase",
            "asciifolding"
          ]
        }
      }
    }
  }
}
```
`filter` — нормализирует поисковые токены.
- [`lowercase`](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-lowercase-tokenfilter.html) 
- [`asciifolding`](https://www.elastic.co/guide/en/elasticsearch/guide/current/asciifolding-token-filter.html)

`char_filter` — используются для предварительной обработки потока символов перед его передачей токенайзеру. 
- [`html_strip`](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-htmlstrip-charfilter.html)
- [`mapping`](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-mapping-charfilter.html)
- [`pattern_replace`](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-pattern-replace-charfilter.html)

`tokenizer` — получает поток символов, разбивает его на отдельные токены (обычно отдельные слова) и выводит их.
- [`standard`](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-standard-tokenizer.html)
- [`ngram`](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-ngram-tokenizer.html) 
- [`edge_ngram`](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-edgengram-tokenizer.html)


```csharp
----------------------------------------------------------------------
BeginRequest: 03.05.2019 3:58:17

REQUEST URL
Host URL: elastic.aws.cloud.es.io
Resource: POST _analyze

REQUEST BODY
{
  "tokenizer": "ngram",
  "text": "Методическое пособие релиз-инженера 1С и не только"
}

RESPONSE BODY
Result: 200
{"tokens":[{"token":"М","start_offset":0,"end_offset":1,"type":"word","position":0},{"token":"Ме","start_offset":0,"end_offset":2,"type":"word","position":1},{"token":"е","start_offset":1,"end_offset":2,"type":"word","position":2},{"token":"ет","start_offset":1,"end_offset":3,"type":"word","position":3},{"token":"т","start_offset":2,"end_offset":3,"type":"word","position":4},{"token":"то","start_offset":2,"end_offset":4,"type":"word","position":5},{"token":"о","start_offset":3,"end_offset":4,"type":"word","position":6},{"token":"од","start_offset":3,"end_offset":5,"type":"word","position":7},{"token":"д","start_offset":4,"end_offset":5,"type":"word","position":8},{"token":"ди","start_offset":4,"end_offset":6,"type":"word","position":9},{"token":"и","start_offset":5,"end_offset":6,"type":"word","position":10},{"token":"ич","start_offset":5,"end_offset":7,"type":"word","position":11},{"token":"ч","start_offset":6,"end_offset":7,"type":"word","position":12},{"token":"че","start_offset":6,"end_offset":8,"type":"word","position":13},{"token":"е","start_offset":7,"end_offset":8,"type":"word","position":14},{"token":"ес","start_offset":7,"end_offset":9,"type":"word","position":15},{"token":"с","start_offset":8,"end_offset":9,"type":"word","position":16},{"token":"ск","start_offset":8,"end_offset":10,"type":"word","position":17},{"token":"к","start_offset":9,"end_offset":10,"type":"word","position":18},{"token":"ко","start_offset":9,"end_offset":11,"type":"word","position":19},{"token":"о","start_offset":10,"end_offset":11,"type":"word","position":20},{"token":"ое","start_offset":10,"end_offset":12,"type":"word","position":21},{"token":"е","start_offset":11,"end_offset":12,"type":"word","position":22},{"token":"е ","start_offset":11,"end_offset":13,"type":"word","position":23},{"token":" ","start_offset":12,"end_offset":13,"type":"word","position":24},{"token":" п","start_offset":12,"end_offset":14,"type":"word","position":25},{"token":"п","start_offset":13,"end_offset":14,"type":"word","position":26},{"token":"по","start_offset":13,"end_offset":15,"type":"word","position":27},{"token":"о","start_offset":14,"end_offset":15,"type":"word","position":28},{"token":"ос","start_offset":14,"end_offset":16,"type":"word","position":29},{"token":"с","start_offset":15,"end_offset":16,"type":"word","position":30},{"token":"со","start_offset":15,"end_offset":17,"type":"word","position":31},{"token":"о","start_offset":16,"end_offset":17,"type":"word","position":32},{"token":"об","start_offset":16,"end_offset":18,"type":"word","position":33},{"token":"б","start_offset":17,"end_offset":18,"type":"word","position":34},{"token":"би","start_offset":17,"end_offset":19,"type":"word","position":35},{"token":"и","start_offset":18,"end_offset":19,"type":"word","position":36},{"token":"ие","start_offset":18,"end_offset":20,"type":"word","position":37},{"token":"е","start_offset":19,"end_offset":20,"type":"word","position":38},{"token":"е ","start_offset":19,"end_offset":21,"type":"word","position":39},{"token":" ","start_offset":20,"end_offset":21,"type":"word","position":40},{"token":" р","start_offset":20,"end_offset":22,"type":"word","position":41},{"token":"р","start_offset":21,"end_offset":22,"type":"word","position":42},{"token":"ре","start_offset":21,"end_offset":23,"type":"word","position":43},{"token":"е","start_offset":22,"end_offset":23,"type":"word","position":44},{"token":"ел","start_offset":22,"end_offset":24,"type":"word","position":45},{"token":"л","start_offset":23,"end_offset":24,"type":"word","position":46},{"token":"ли","start_offset":23,"end_offset":25,"type":"word","position":47},{"token":"и","start_offset":24,"end_offset":25,"type":"word","position":48},{"token":"из","start_offset":24,"end_offset":26,"type":"word","position":49},{"token":"з","start_offset":25,"end_offset":26,"type":"word","position":50},{"token":"з-","start_offset":25,"end_offset":27,"type":"word","position":51},{"token":"-","start_offset":26,"end_offset":27,"type":"word","position":52},{"token":"-и","start_offset":26,"end_offset":28,"type":"word","position":53},{"token":"и","start_offset":27,"end_offset":28,"type":"word","position":54},{"token":"ин","start_offset":27,"end_offset":29,"type":"word","position":55},{"token":"н","start_offset":28,"end_offset":29,"type":"word","position":56},{"token":"нж","start_offset":28,"end_offset":30,"type":"word","position":57},{"token":"ж","start_offset":29,"end_offset":30,"type":"word","position":58},{"token":"же","start_offset":29,"end_offset":31,"type":"word","position":59},{"token":"е","start_offset":30,"end_offset":31,"type":"word","position":60},{"token":"ен","start_offset":30,"end_offset":32,"type":"word","position":61},{"token":"н","start_offset":31,"end_offset":32,"type":"word","position":62},{"token":"не","start_offset":31,"end_offset":33,"type":"word","position":63},{"token":"е","start_offset":32,"end_offset":33,"type":"word","position":64},{"token":"ер","start_offset":32,"end_offset":34,"type":"word","position":65},{"token":"р","start_offset":33,"end_offset":34,"type":"word","position":66},{"token":"ра","start_offset":33,"end_offset":35,"type":"word","position":67},{"token":"а","start_offset":34,"end_offset":35,"type":"word","position":68},{"token":"а ","start_offset":34,"end_offset":36,"type":"word","position":69},{"token":" ","start_offset":35,"end_offset":36,"type":"word","position":70},{"token":" 1","start_offset":35,"end_offset":37,"type":"word","position":71},{"token":"1","start_offset":36,"end_offset":37,"type":"word","position":72},{"token":"1С","start_offset":36,"end_offset":38,"type":"word","position":73},{"token":"С","start_offset":37,"end_offset":38,"type":"word","position":74},{"token":"С ","start_offset":37,"end_offset":39,"type":"word","position":75},{"token":" ","start_offset":38,"end_offset":39,"type":"word","position":76},{"token":" и","start_offset":38,"end_offset":40,"type":"word","position":77},{"token":"и","start_offset":39,"end_offset":40,"type":"word","position":78},{"token":"и ","start_offset":39,"end_offset":41,"type":"word","position":79},{"token":" ","start_offset":40,"end_offset":41,"type":"word","position":80},{"token":" н","start_offset":40,"end_offset":42,"type":"word","position":81},{"token":"н","start_offset":41,"end_offset":42,"type":"word","position":82},{"token":"не","start_offset":41,"end_offset":43,"type":"word","position":83},{"token":"е","start_offset":42,"end_offset":43,"type":"word","position":84},{"token":"е ","start_offset":42,"end_offset":44,"type":"word","position":85},{"token":" ","start_offset":43,"end_offset":44,"type":"word","position":86},{"token":" т","start_offset":43,"end_offset":45,"type":"word","position":87},{"token":"т","start_offset":44,"end_offset":45,"type":"word","position":88},{"token":"то","start_offset":44,"end_offset":46,"type":"word","position":89},{"token":"о","start_offset":45,"end_offset":46,"type":"word","position":90},{"token":"ол","start_offset":45,"end_offset":47,"type":"word","position":91},{"token":"л","start_offset":46,"end_offset":47,"type":"word","position":92},{"token":"ль","start_offset":46,"end_offset":48,"type":"word","position":93},{"token":"ь","start_offset":47,"end_offset":48,"type":"word","position":94},{"token":"ьк","start_offset":47,"end_offset":49,"type":"word","position":95},{"token":"к","start_offset":48,"end_offset":49,"type":"word","position":96},{"token":"ко","start_offset":48,"end_offset":50,"type":"word","position":97},{"token":"о","start_offset":49,"end_offset":50,"type":"word","position":98}]}

DoneResponse: 03.05.2019 3:58:18
Overall Elapsed: 845 ms
----------------------------------------------------------------------
```

https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-tokenizers.html

### Создание своего индекса c указанным маппингом 

```csharp
----------------------------------------------------------------------
BeginRequest: 02.05.2019 16:53:32

REQUEST URL
Host URL: elastic.aws.cloud.es.io
Resource: PUT /product

REQUEST BODY 
{
  "settings": {
    "analysis": {
      "analyzer": {
        "partial_tokenizer": {
          "tokenizer": "ngram",
          "min_gram": 2,
          "max_gram": 30,
          "filter": [
            "lowercase"
          ]
        }
      }
    }
  },
  "mappings": {
    "properties": {
      "Код": {
        "type": "keyword",
        "boost": 20,
        "ignore_above": 11
      },
      "Code": {
        "type": "keyword",
        "boost": 10,
        "ignore_above": 11
      },
      "Sku": {
        "type": "text",
        "boost": 1.5,
        "fields": {
          "keyword": {
            "type": "keyword",
            "boost": 5,
            "ignore_above": 35
          }
        }
      },
      "Name": {
        "type": "text",
        "analyzer": "standard",
        "fields": {
          "ngram": {
            "type": "text",
            "analyzer": "partial_tokenizer"
          }
        }
      },
      "FullName": {
        "type": "text",
        "analyzer": "standard",
        "fields": {
          "ngram": {
            "type": "text",
            "analyzer": "partial_tokenizer"
          }
        }
      },
      "Description": {
        "type": "text",
        "analyzer": "standard"
      }
    }
  }
}


RESPONSE BODY
Result: 200 
{
  "acknowledged": true,
  "shards_acknowledged": true,
  "index": "product"
}

DoneResponse: 02.05.2019 16:53:32
Overall Elapsed: 247 ms
----------------------------------------------------------------------
```

### Pipelines

```csharp
PUT _ingest/pipeline/my_pipeline
{
  "description": "Полезная информация или описание",
  "processors": [
    {
      "set": {
        "field": "_id",
        "value": "{{id}}"
      }
    }
  ]
}

PUT product/_doc/1?pipeline=my_pipeline
{
    "name" : "Методическое пособие релиз-инженера 1С и не только, часть 3",
    "id" : "3"
}

GET product/_doc/3
```
