1）ELK 搭建

ELK是一整套开源日志管理方案，通常配套使用，并且都先后并入 elastic 公司名下，因而常常合并简称 ELK。但是三者都是相互独立的，具有各自的功能：

- Logstash 负责文本数据的收集、处理、存储，是一个数据处理管道，它转换日志消息并将其发送到 Elasticsearch 来存储
- Elasticsearch 负责数据的检索，是一个构建于 Apache Lucene 之上的开源搜索引擎，它充当着您的日志消息的一个无模式的 JSON 数据库。
- Kibana 负责数据的可视化（主要是Node.js）

Docker 是一个开放平台，开发人员可在它之上构建、发布和运行分布式应用程序或服务。它旨在自动化应用程序在沙箱化的软件容器中的部署，并提供另一个抽象层。在您希望发布一个沙箱化的容器来存放日志时，Docker 非常适合您的需求。

```
$ git clone git@github.com:deviantony/docker-elk.git
$ cd docker-elk
$ docker-compose up [--force-recreate]
```

如果没有docker和docker-compose，又是java，又是node，外加各种elk配置，配置起来真的是非常麻烦。

默认占用的端口如下。

- 5000: Logstash TCP input.
- 9200: Elasticsearch HTTP
- 9300: Elasticsearch TCP transport
- 5601: Kibana

启动成功后，在浏览器中打开http://127.0.0.1:5601/，界面如下。

![屏幕快照 2018-07-31 下午5.34.19](media/%E5%B1%8F%E5%B9%95%E5%BF%AB%E7%85%A7%202018-07-31%20%E4%B8%8B%E5%8D%885.34.19.png)


2）APM

点击上面Add APM链接可以看到具体安装步骤。

```
$ curl -L -O https://artifacts.elastic.co/downloads/apm-server/apm-server-6.3.2-darwin-x86_64.tar.gz
$ tar xzvf apm-server-6.3.2-darwin-x86_64.tar.gz
$ cd apm-server-6.3.2-darwin-x86_64/
$ ./apm-server setup
Loaded index template
Loading dashboards (Kibana must be running and reachable)
Loaded dashboards
```

setup命令会初始化apm数据，自动添加如下面板。

![屏幕快照 2018-07-31 下午5.43.44](media/%E5%B1%8F%E5%B9%95%E5%BF%AB%E7%85%A7%202018-07-31%20%E4%B8%8B%E5%8D%885.43.44.png)

启动apm服务器

```
$./apm-server -e
```

修改koa应用代码，添加apm的探针，在koa-generator生成的代码bin/www最上面

```
global.apm = require('elastic-apm-node').start({
  serviceName: 'koa2-demo'
})
```

在 Elastic APM 中，有两个术语：

- transaction：一组 traces 的集合，例如：HTTP 请求。
- trace：一个事件及持续时间，例如：SQL 查询。

在app.js里，修改logger中间件，设置Transaction名称。

```
// logger
app.use(async (ctx, next) => {
  const start = new Date()
  await next()
  const ms = new Date() - start
  console.log(`${ctx.method} ${ctx._matchedRoute} ${ctx.url} - ${ms}ms`)

  apm.setTransactionName(`${ctx.method} ${ctx.url}`)
})
```

然后通过`npm start`启动，访问2个请求

```
$ curl http://127.0.0.1:3000/
$ curl http://127.0.0.1:3000/users
```

在可视化可以看到koa2-demo

![屏幕快照 2018-07-31 下午8.45.12](media/%E5%B1%8F%E5%B9%95%E5%BF%AB%E7%85%A7%202018-07-31%20%E4%B8%8B%E5%8D%888.45.12.png)

点koa2-demo链接，进入到详情

![屏幕快照 2018-07-31 下午8.42.16](media/%E5%B1%8F%E5%B9%95%E5%BF%AB%E7%85%A7%202018-07-31%20%E4%B8%8B%E5%8D%888.42.16.png)

至此，你已经可以看到平均响应时长，请求数量，均值水位线等信息，可以满足日常监控需求。对于错误追踪也是非常简单的。

在router/index.js里增加

```
router.get('/error', function (ctx, next) {
  let err = new Error('apm.captureError(err)')
  apm.captureError(err)
  throw err
})
```

重启测试程序，并发起一次请求http://127.0.0.1:3000/error。回到 Kibana，单击 Dashboard -> [APM] Errors 可以看到错误日志记录（自动聚合）和图表，在错误日志中展示了错误代码及行数、上下几行代码、父级函数名和所在文件等信息。

![屏幕快照 2018-07-31 下午9.00.23](media/%E5%B1%8F%E5%B9%95%E5%BF%AB%E7%85%A7%202018-07-31%20%E4%B8%8B%E5%8D%889.00.23.png)

