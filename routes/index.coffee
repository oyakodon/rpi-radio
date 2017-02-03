express = require 'express'
router = express.Router()

# GET home page.
router.get '/', (req, res, next) ->
  res.render 'index'

router.post '/play', (req, res, next) ->
  console.log req.body.ch

  spawn = require('child_process').spawn
  r_kill = spawn 'pkill', ['-f', 'mplayer', '-9']

  r_kill.on 'close', (code) ->
    r_radiko = spawn "bash", ['lib/radiko.sh', '-p', req.body.ch]
  
  res.send true

router.post '/nhk', (req, res, next) ->
  console.log req.body.ch

  spawn = require('child_process').spawn
  r_kill = spawn 'pkill', ['-f', 'mplayer', '-9']

  r_kill.on 'close', (code) ->
    r_radiko = spawn "bash", ['lib/rajiru.sh', '-p', req.body.ch]
  
  res.send true
  
router.post '/stop', (req, res, next) ->
  spawn = require('child_process').spawn
  run = spawn 'pkill', ['-f', 'mplayer', '-9']
	
  res.send true

module.exports = router
