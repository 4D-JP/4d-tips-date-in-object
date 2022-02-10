# JSONコマンドと日付型の扱いについての考察

v16以前に作成されたアプリケーションは，デフォルトの設定でオブジェクト（エンティティを除く）の**日付型プロパティ**がサポートされておらず，日付型をプロパティに代入すると文字列が書き込まれ，プロパティを日付型に代入するとISOフォーマットの日付文字列として値が解釈されます。これは，データベースパラメーター`85` (Dates inside objects) の`1` (String type with time zone) ，あるいは互換性のデータベース設定「オブジェクトではISO日付フォーマットの代わりに日付型を使用する」が**無効**に設定された状態に相当します。

<img width="517" alt="date" src="https://user-images.githubusercontent.com/10509075/153347364-8aad9ae0-7706-48a2-8485-667ed1455d8b.png">

たとえば

```4d
$o:=New object("date"; !2022-02-10!)
```

のようなコードをv16以前に作成されたアプリケーションで実行した場合，ローカルタイムゾーンが日本であれば，`2022-02-09T15:00:00.000Z`という文字列がオブジェクトに代入されます。日本時間の2月10日深夜0時は，協定標準時の2月9日の午後3時だからです。

このモードでは，日付風の文字列に特別な意味はありません。JSONのデータ型が文字列であれば，そのプロパティは文字列として扱われます。

```4d
$o:=JSON Parse("{\"date\":\"2022-02-10\"}")
```

