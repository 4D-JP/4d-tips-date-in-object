# JSONコマンドと日付型の扱いについての考察

v16以前に作成されたアプリケーションは，デフォルトの設定でオブジェクト（エンティティを除く）の**日付型プロパティ**がサポートされておらず，日付型をプロパティに代入すると文字列が書き込まれ，プロパティを日付型に代入するとISOフォーマットの日付文字列として値が解釈されます。これは，[データベースパラメーター](https://doc.4d.com/4Dv19/4D/19.1/SET-DATABASE-PARAMETER.301-5653585.ja.html)`85` (Dates inside objects) が`1` (String type with time zone) にセットされた状態，あるいは[互換性のデータベース設定](https://doc.4d.com/4Dv19/4D/19/Compatibility-page.300-5416914.ja.html)「オブジェクトではISO日付フォーマットの代わりに日付型を使用する」が**無効**に設定された状態に相当します。通常，互換性の設定が無効にされていることは「旧式の仕様を踏襲する（下方互換性）」を意味します。

<img width="517" alt="date" src="https://user-images.githubusercontent.com/10509075/153347364-8aad9ae0-7706-48a2-8485-667ed1455d8b.png">

たとえば

```4d
$o:=New object("date"; !2022-02-10!)
```

のようなコードをv16以前に作成されたアプリケーションで実行した場合，ローカルタイムゾーンが日本であれば，`2022-02-09T15:00:00.000Z`という文字列がオブジェクトに代入されます。日本時間の2月10日深夜0時は，協定標準時の2月9日の午後3時だからです。

このモードでは，日付風の文字列に特別な意味はありません。JSONのデータ型が文字列であれば，そのプロパティは文字列として扱われます。下記の例では`$o.date`のプロパティが`"2022-02-10"`という文字列になります。

```4d
$o:=JSON Parse("{\"date\":\"2022-02-10\"}")
```

プロジェクトモードでは，「標準のXPathを使用する」のように後から追加されたものを除き，**互換性のデータベース設定はすべてリセットされ，v17以降の設定になります**。強制的に解除された設定は，変換ログファイルに警告として出力されます。

```json
{
	"messages": [
		{
			"message": "Compatibility setting 'Use date type instead of ISO date format in objects' switched on.",
			"severity": "warning"
		}
	],
	"success": true
}
```

プロジェクトモード（またはv17以降に作成したストラクチャファイル）では，新しい仕様が適用されるため，前述したようなコードでは**日付風の文字列が日付に変換されます**。JSON内の"YYYY-MM-DD" という日付フォーマットの文字列が自動的に変換されることは[`JSON Parse`](https://doc.4d.com/4Dv19/4D/19.1/JSON-Parse.301-5653601.ja.html)のドキュメントに記述されています。

<img width="741" alt="new" src="https://user-images.githubusercontent.com/10509075/153352096-e8c6f2cf-5158-4a72-9da7-aae505d3d7f1.png">

特定のフォーマットに合致する文字列が自動的に変換されることに留意してください。XXXX-XX-XXのような文字列は，それが「製品コード」であったとしても，日付文字列として解釈され，日付に変換される，ということです。

<img width="741" alt="code" src="https://user-images.githubusercontent.com/10509075/153352870-d2996b77-52ce-494f-b7e3-d6cb77856791.png">

プロジェクトモードであっても，データベースパラメーター`85` (Dates inside objects) は`SET DATABASE PARAMETER`で変更することができます。設定のスコープは「カレントプロセス」です。しかしながら，`SET DATABASE PARAMETER`はスレッドアンセーフコマンドなので，スコープのセレクターがインタープロセスであるかどうかに関わりなく，プリエンプティブプロセスでは呼び出すことができません。

#### プリエンプティブプロセスからスレッドアンセーフコマンドをワーカー経由でコール

`Signal`を使用し，コオペレアティブモードのワーカーにスレッドアンセーフコマンドを代行させることができます。

簡単なクラスを作成します。

```4d
Function parse($json : Text; $datesInsideObjects : Integer; $timesInsideObjects : Integer)->$value : Variant
	
	$params:=New object
	$signal:=New signal
	
	If (Count parameters>1)
		$params.datesInsideObjects:=$datesInsideObjects
	End if 
	
	If (Count parameters>1)
		$params.timesInsideObjects:=$timesInsideObjects
	End if 
	
	CALL WORKER("JSON"; "parse"; $json; $params; $signal)
	
	$signal.wait()
	
	$value:=$signal.value
```

呼び出されるプロジェクトメソッドは「プリエンプティブモードでは実行不可」なので，スレッドアンセーフなコマンドを実行することができます。

```4d
#DECLARE($json : Text; $params : Object; $signal : 4D.Signal)

If ($params.datesInsideObjects#Null)
	SET DATABASE PARAMETER(Dates inside objects; $params.datesInsideObjects)
End if 

If ($params.timesInsideObjects#Null)
	SET DATABASE PARAMETER(Times inside objects; $params.timesInsideObjects)
End if 

var $value : Variant

$value:=JSON Parse($json)


If (Not(Process aborted))
	
	Use ($signal)
		
		Case of 
			: (Value type($value)=Is object)
				
				$signal.value:=OB Copy($value; ck shared; $signal)
				
			: (Value type($value)=Is collection)
				
				$signal.value:=$value.copy(ck shared; $signal)
				
			Else 
				
				$signal.value:=$value
				
		End case 
		
		$signal.trigger()
		
	End use 
	
End if 

KILL WORKER
```



