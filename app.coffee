express = require 'express'
path = require 'path'
favicon = require 'serve-favicon'
logger = require 'morgan'
cookieParser = require 'cookie-parser'
bodyParser = require 'body-parser'
coffeeMiddleware = require 'coffee-middleware'

index = require './routes/index'

app = express()

# view engine setup
app.set 'views', path.join __dirname, 'views'
app.set 'view engine', 'jade'

app.use logger 'dev'
app.use bodyParser.json()
app.use bodyParser.urlencoded { extended: false }
app.use cookieParser()
app.use express.static path.join __dirname, 'public'

app.use coffeeMiddleware(
  src: path.join(__dirname, "public")
  compress: true
  bare: true
)

app.use '/', index

# catch 404 and forward to error handler
app.use (req, res, next) ->
  err = new Error 'Not Found'
  err.status = 404
  next err

# error handler
app.use (err, req, res, next) ->
  # set locals, only providing error in development
  res.locals.message = err.message
  res.locals.error = if req.app.get 'env' is 'development' then err else {}

  # render the error page
  res.status err.status || 500
  res.render 'error'

module.exports = app
