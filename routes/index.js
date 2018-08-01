const router = require('koa-router')()

router.get('/', async (ctx, next) => {

  await ctx.render('index', {
    title: 'Hello Koa 2!'
  })
})

router.get('/error', function (ctx, next) {
  let err = new Error('apm.captureError(err)')
  apm.captureError(err)
  throw err
})

module.exports = router
