'use strict'

class appCtrler
  constructor: ($scope, $http) ->
    $scope.btnData_radiko = [{text:"TBCラジオ", ch:"TBC"}
      {text:"ラジオNIKKEI第1", ch:"RN1"}
      {text:"ラジオNIKKEI第2", ch:"RN2"}
      {text:"Date fm", ch:"DATEFM"}
      {text:"放送大学", ch:"HOUSOU-DAIGAKU"}]

    $scope.btnData_nhk = [{text:"NHK仙台第一", ch:"NHK1_SENDAI"}
      {text:"NHK第二", ch:"NHK2"}
      {text:"NHK仙台FM", ch:"FM_SENDAI"}]

    $scope.btn_radikoClicked = (idx) ->
      for val, i in $scope.btnData_radiko
        $scope.btnData_radiko[i]['select'] = false
      
      for val, i in $scope.btnData_nhk
        $scope.btnData_nhk[i]['select'] = false

      $scope.btnData_radiko[idx]['select'] = true

      # alert "Selected: " + $scope.btnData_radiko[idx]['text']
        
      $http.post './play', {ch: $scope.btnData_radiko[idx]['ch']}
        .then (res) ->
          if res.data
            $scope.result = "success"
            $scope.msg = $scope.btnData_radiko[idx]['text'] + "の再生を開始しました。"
          else
            $scope.result = "error"
            $scope.msg = "再生時にエラーが発生しました。"

    $scope.btn_nhkClicked = (idx) ->
      for val, i in $scope.btnData_nhk
        $scope.btnData_nhk[i]['select'] = false
      
      for val, i in $scope.btnData_radiko
        $scope.btnData_radiko[i]['select'] = false

      $scope.btnData_nhk[idx]['select'] = true

      # alert "Selected: " + $scope.btnData_nhk[idx]['text']
        
      $http.post './nhk', {ch: $scope.btnData_nhk[idx]['ch']}
        .then (res) ->
          if res.data
            $scope.result = "success"
            $scope.msg = $scope.btnData_nhk[idx]['text'] + "の再生を開始しました。"
          else
            $scope.result = "error"
            $scope.msg = "再生時にエラーが発生しました。"

    $scope.stopClicked = () ->
      $http.post './stop'
        .then (res) ->
          if res.data
            $scope.result = "success"
            $scope.msg = "再生を停止しました。"
          else
            $scope.result = "error"
            $scope.msg = "再生時にエラーが発生しました。"



app = angular.module("rpi-radio", [])

app.controller("rpi-radio-ctrl", appCtrler)

