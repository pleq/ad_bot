### emir_m@tvsi.ru ###
### Скрипт отсылает события журналов Windows в чат Телеграм ###

Import-Module -Name "PoshGram"
[string]$botToken="342342341234:SDGFGDFHds-oVDHYUsbdBFAZDFBFDZFV-w1" # bot token here (don't try, this one is fake :)
[string]$chatId="-523645345634" # chat ID here

$EventId = 4720, 4726, 4729, 4728, 5139, 4743, 4741, 4719, 1102, 4725, 4698, 4740, 4727, 4754

### внутри файла дата предыдущего запуска задачи (скрипта) в текстовом виде ###
$prev_date = Get-Content .\date.txt

### преобразование строки в объект [Datetime] ###
$start_time = [Datetime]::ParseExact($prev_date, 'yyyy-MM-ddTHH:mm:ss.fffzzz', $null)

### запись текущей даты (время запуска задачи) ###
$current_date = Get-Date 

### StartTime = дата предыдущего запуска задачи, которую получили из файла .\date.txt ###
### EndTime = Get-Date текущее время ###
$params = @{Logname = "Security" ; ID = $EventId; StartTime = $start_time; EndTime = $current_date}

### Get-WinEvent получает все события с указанными ID, произошедшие за последние N минут, начиная с самых "старых" ###
$events = Get-WinEvent -Oldest -FilterHashtable $params

### запись даты запуска текущей задачи в файл .\date.txt ###
$end_time = Get-Date $current_date -Format 'yyyy-MM-ddTHH:mm:ss.fffzzz'
$end_time | Out-File .\date.txt

### имя хоста, с которого запускается скрипт и логи которого скрипт читает ###
$hostname = $env:computername

foreach ($entry in $events) 
{
  switch ($entry.Id)
  {
    ### Computer account was moved ###
    5139 
    {
      # $name = $(($entry.Message).Split([Environment]::NewLine))[0]
      $time = $entry.TimeCreated
      $ev_date = $time.ToString("HH:mm:ss dd/MM/yyyy")
      $computer = $entry.Properties[8].Value.Split(",")[0].Split("=")[1]
      $oldDN = $entry.Properties[8].Value.Split(",")[1].Split("=")[1]
      $newDN = $entry.Properties[9].Value.Split(",")[1].Split("=")[1]
      $admin = $entry.Properties[3].Value
      $domain = $entry.Properties[4].Value

      $message = "<b>computer account was moved</b>
source: <pre>$hostname</pre>
admin: <pre>$domain/$admin</pre>
computer: <pre>$domain/$computer</pre>
from OU: <pre>$oldDN</pre>
to new OU: <pre>$newDN</pre>
time: <pre>$ev_date</pre>"
      Send-TelegramTextMessage -BotToken $botToken -ChatID $chatId -Message $message
    }
    
    ### Computer account was created ###
    4741 
    {
      # $name = $(($entry.Message).Split([Environment]::NewLine))[0]
      $time = $entry.TimeCreated
      $ev_date = $time.ToString("HH:mm:ss dd/MM/yyyy")
      $computer = $entry.Properties[0].Value
      $admin = $entry.Properties[4].Value
      $domain = $entry.Properties[1].Value
      $OU = Get-ADComputer -Identity $entry.Properties[0].Value -Properties DistinguishedName | Select-Object -ExpandProperty DistinguishedName
      $OU = $OU.Remove($OU.IndexOf(",DC=",13))

      $message = "<b>computer account was created</b>
source: <pre>$hostname</pre>
admin: <pre>$domain/$admin</pre>
computer: <pre>$domain/$computer</pre>
OU: <pre>$OU</pre>
time: <pre>$ev_date</pre>"
      Send-TelegramTextMessage -BotToken $botToken -ChatID $chatId -Message $message
    }

    ### Computer account was deleted ###
    4743 
    {
      # $name = $(($entry.Message).Split([Environment]::NewLine))[0]
      $time = $entry.TimeCreated
      $ev_date = $time.ToString("HH:mm:ss dd/MM/yyyy")
      $computer = $entry.Properties[0].Value
      $admin = $entry.Properties[4].Value
      $domain = $entry.Properties[1].Value

      $message = "<b>computer account was deleted</b>
source: <pre>$hostname</pre>
admin: <pre>$domain/$admin</pre>
computer: <pre>$domain/$computer</pre>
time: <pre>$ev_date</pre>"
      Send-TelegramTextMessage -BotToken $botToken -ChatID $chatId -Message $message
    }

    ### User account was created ###
    4720 
    {
      # $name = $(($entry.Message).Split([Environment]::NewLine))[0]
      $time = $entry.TimeCreated
      $ev_date = $time.ToString("HH:mm:ss dd/MM/yyyy")
      $user = $entry.Properties[0].Value
      $admin = $entry.Properties[4].Value
      $domain = $entry.Properties[1].Value
      $displayName = Get-ADUser -Identity $user -Properties DisplayName | Select-Object -ExpandProperty DisplayName

      $message = "<b>user account was created</b>
source: <pre>$hostname</pre>
admin: <pre>$domain/$admin</pre>
user: <pre>$domain/$user</pre>
display name: <pre>$displayName</pre>
time: <pre>$ev_date</pre>"
      Send-TelegramTextMessage -BotToken $botToken -ChatID $chatId -Message $message
    }

    ### User account was deleted ###
    4726 
    {
      # $name = $(($entry.Message).Split([Environment]::NewLine))[0]
      $time = $entry.TimeCreated
      $ev_date = $time.ToString("HH:mm:ss dd/MM/yyyy")
      $user = $entry.Properties[0].Value
      $admin = $entry.Properties[4].Value
      $domain = $entry.Properties[1].Value

      $message = "<b>user account was deleted</b>
source: <pre>$hostname</pre>
admin: <pre>$domain/$admin</pre>
user: <pre>$domain/$user</pre>
time: <pre>$ev_date</pre>"
      Send-TelegramTextMessage -BotToken $botToken -ChatID $chatId -Message $message
    }
    
    ### User account was added to group ###
    4728 
    {
      # $name = $(($entry.Message).Split([Environment]::NewLine))[0]
      $time = $entry.TimeCreated
      $ev_date = $time.ToString("HH:mm:ss dd/MM/yyyy")
      $admin = $entry.Properties[6].Value
      $domain = $entry.Properties[3].Value
      $cn = $entry.Properties[0].Value
      $group = $entry.Properties[2].Value
      $user = $cn.Remove($cn.IndexOf(",DC=",13))
      
      $message = "<b>user account was added to $group</b>
source: <pre>$hostname</pre>
admin: <pre>$domain/$admin</pre>
user: <pre>$user</pre>
time: <pre>$ev_date</pre>"
      Send-TelegramTextMessage -BotToken $botToken -ChatID $chatId -Message $message
    }

    ### User account was removed from group ###
    4729 
    {
      # $name = $(($entry.Message).Split([Environment]::NewLine))[0]
      $time = $entry.TimeCreated
      $ev_date = $time.ToString("HH:mm:ss dd/MM/yyyy")
      $admin = $entry.Properties[6].Value
      $domain = $entry.Properties[3].Value
      $cn = $entry.Properties[0].Value
      $group = $entry.Properties[2].Value
      $user = $cn.Remove($cn.IndexOf(",DC=",13))
      
      $message = "<b>user account was removed from $group</b>
source: <pre>$hostname</pre>
admin: <pre>$domain/$admin</pre>
user: <pre>$user</pre>
time: <pre>$ev_date</pre>"
      Send-TelegramTextMessage -BotToken $botToken -ChatID $chatId -Message $message
    }

    ### system audit policy was changed ###
    4719 
    {
      # $name = $(($entry.Message).Split([Environment]::NewLine))[0]
      $admin = $entry.Properties[1].Value
      $domain = $entry.Properties[2].Value
      $category = $entry.Properties[4].Value
      $subcategory = $entry.Properties[5].Value
      $changes = $entry.Properties[7].Value

      $message = "<b>system audit policy changed </b>
source: <pre>$hostname</pre>
time: <pre>$ev_date</pre>
admin: <pre>$domain/$admin</pre>
category: <pre>$category</pre>
subcategory: <pre>$subcategory</pre>
changes: <pre>$changes</pre>"

      Send-TelegramTextMessage -BotToken $botToken -ChatID $chatId -Message $message
    }

    ### audit log was cleared. This can relate to a potential attack ###
    1102 
    {
      # $name = $(($entry.Message).Split([Environment]::NewLine))[0]
      $time = $entry.TimeCreated
      $ev_date = $time.ToString("HH:mm:ss dd/MM/yyyy")
      
      $message = "<b>audit log was cleared: potential attack</b>
source: <pre>$hostname</pre>
time: <pre>$ev_date</pre>"

      Send-TelegramTextMessage -BotToken $botToken -ChatID $chatId -Message $message
    }

    ### user account was disabled ###
    4725 
    {
      # $name = $(($entry.Message).Split([Environment]::NewLine))[0]
      $time = $entry.TimeCreated
      $ev_date = $time.ToString("HH:mm:ss dd/MM/yyyy")

      $account = $entry.Properties[0].Value
      $account_domain = $entry.Properties[1].Value
      $admin = $entry.Properties[4].Value
      $domain = $entry.Properties[5].Value
      
      $message = "<b>user account was disabled</b>
source: <pre>$hostname</pre>
user: <pre>$account_domain/$account</pre>
admin: <pre>$domain/$admin</pre>
time: <pre>$ev_date</pre>"

      Send-TelegramTextMessage -BotToken $botToken -ChatID $chatId -Message $message
    }

    ### scheduled task was created ###
    4698 
    {
      # $name = $(($entry.Message).Split([Environment]::NewLine))[0]
      $time = $entry.TimeCreated
      $ev_date = $time.ToString("HH:mm:ss dd/MM/yyyy")

      $admin = $entry.Properties[1].Value
      $domain = $entry.Properties[2].Value
      $task = $entry.Properties[4].Value
      
      $message = "<b>scheduled task was created</b>
source: <pre>$hostname</pre>
user: <pre>$domain/$admin</pre>
task: <pre>$task</pre>
time: <pre>$ev_date</pre>"

      if ($task -ne "\Microsoft\Windows\UpdateOrchestrator\AC Power Download") {
        Send-TelegramTextMessage -BotToken $botToken -ChatID $chatId -Message $message
      }
      
    }

    ### account locked out  ###
    4740 
    {
      # $name = $(($entry.Message).Split([Environment]::NewLine))[0]
      $time = $entry.TimeCreated
      $ev_date = $time.ToString("HH:mm:ss dd/MM/yyyy")

      $user = $entry.Properties[0].Value
      $domain = $entry.Properties[5].Value
      $computer = $entry.Properties[1].Value
      
      $message = "<b>account locked out</b>
source: <pre>$hostname</pre>
user: <pre>$domain/$user</pre>
host: <pre>$computer</pre>
time: <pre>$ev_date</pre>"

      Send-TelegramTextMessage -BotToken $botToken -ChatID $chatId -Message $message
    }

    ### global group created ###
    4727 
    {
      # $name = $(($entry.Message).Split([Environment]::NewLine))[0]
      $time = $entry.TimeCreated
      $ev_date = $time.ToString("HH:mm:ss dd/MM/yyyy")
      
      $message = "<b>global group created</b>
time: <pre>$ev_date</pre>"

      Send-TelegramTextMessage -BotToken $botToken -ChatID $chatId -Message $message
    }

    ### universal group created ###
    4754 
    {
      # $name = $(($entry.Message).Split([Environment]::NewLine))[0]
      $time = $entry.TimeCreated
      $ev_date = $time.ToString("HH:mm:ss dd/MM/yyyy")
      
      $message = "<b>global group created</b>
time: <pre>$ev_date</pre>"

      Send-TelegramTextMessage -BotToken $botToken -ChatID $chatId -Message $message
    }
  }
}



