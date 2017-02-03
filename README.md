# rpi-radio
Raspberry Piでラジオ(radiko.jp / らじる★らじる)が聞けます。  
ラジオ再生はシェルスクリプト(Bash)、操作用にWebアプリも作りました。  
  
## このアプリについて
- Raspberry Pi向けに作りましたが、Ubuntuでも普通に動きます
- WEBアプリ部は Node.js / AngularJS / Express / CoffeeScript を使用しています
- ネットラジオの聴取部はシェルスクリプト(Bash)で組んでいてRTMPDUMPを使用しています

## 事前準備
- Raspberry Piのセットアップ(ターミナルが開けるところまで)
- **coffeescript npm rtmpdump swftools libxml2-utils mplayer** が必要です
- もちろんClone

## 実行
1. パッケージをインストールします

    
    $npm install

2. サーバを起動します

    
    $coffee bin/www.coffee

3. WEBブラウザで「(サーバのIP):3000」にアクセスし、操作画面が表示されれば実行完了です。

## 注意
- 再生できない場合、再生デバイスを見直してみてください(USBオーディオで再生するようになっています)
  - radiko.sh#L195
  - rajiru.sh#L64
  - 上の2つを「mplayer -」に書き換えるとデフォルトのオーディオで再生されるはずです。  

- 放送局は宮城県のものになっています。変更方法は後日書きます。(public/javascripts/index.coffeeを見ると分かるかも)

## 詳細は
詳しいこと(Raspberry Piのセットアップ等)は、後日ブログにまとめる予定です。  
<http://oykdn.hatenablog.com/>  

## 作った人
Oyakodon  
<http://oykdn.com>  
Twitter: [@alltekito](https://twitter.com/alltekito)  
  
