#Skript shromažďující základní systémové statistiky a provádějící úklid starých kachních záznamů.
Write-Host "Nezavírej tohle okno! `n> Každou hodinu tento skript pošle report, který obsahuje informace o:`n -napájení`n -místo na disku`n -doba běhu systému"
$alive=1
[int]$opscounter = 0
$logfile="$home\kachnolog.html"

function infoDisk 
    {
        $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'" | Select-Object Size, FreeSpace
        $velikost = ("{0} GB" -f [math]::truncate($disk.Size / 1GB))
        $volne = ("{0} GB" -f [math]::truncate($disk.FreeSpace / 1GB))
        $pouzite = ("{0} GB" -f [math]::truncate(($disk.Size - $disk.FreeSpace) /1GB))
        Write-Host "> Využití úložiště: <b>$pouzite</b> / $velikost <br>> Volné místo: <b>$volne</b>;"$((($disk.FreeSpace)*100)/($disk.Size)).ToString("#.##")"%"
    }

function infoBatt
    {
        $battCharge = (gwmi batterystatus -name root\wmi).PowerOnline[0]
        $battLevel = (Get-WmiObject win32_battery).estimatedChargeRemaining
        Write-Host "> Stav baterie:<b>" $battLevel "% </b><br>> Napájení ze stítě:<b>" $battCharge  "</b>"
    }

function infoSys
    {
        $sysFreeRAM = ([math]::round(((Get-WmiObject -Class Win32_OperatingSystem).FreePhysicalMemory / 1024 / 1024), 2))
        $sysRAM = ([math]::round(((Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory / 1024 / 1024 / 1024), 2))
        #$sysUptime = $((Get-Date) - ([Management.ManagementDateTimeConverter]::ToDateTime((Get-WmiObject Win32_OperatingSystem).LastBootUpTime)))
        $sysBootTime= ((gcim Win32_OperatingSystem).LastBootUpTime)
        $usedRAM = $sysRAM - $sysFreeRAM
        Write-Host "> Hostname: $(hostname) <br>> Doba spuštění systému: $sysBootTime <br>> Využití RAM: <b>$usedRAM GB</b> / $sysRAM GB"
    }

function DO-deleteOld
    {
        $cesta = "C:\Zaznamy"
        Remove-FilesCreatedBeforeDate -Path $cesta -DateTime ((Get-Date).AddDays(-7)) -DeletePathIfEmpty Remove-Item -Force
        Write-Host "Byly smazány soubory starší než 7 dní."
    }

function DO-sendMail
    {
    $Username = "email@domain.tld";
    $Password= "***";
    $email= "email@domain.tld"

    $message = new-object Net.Mail.MailMessage;
    $message.From = "$Username";
    $message.To.Add($email);
    $message.Subject = "Status Reporter";
    $message.Body = $(Get-Content $logfile | out-string);
    $message.IsBodyHtml=$true;
    #$attachment = New-Object Net.Mail.Attachment($attachmentpath);
    #$message.Attachments.Add($attachment);

    $smtp = new-object Net.Mail.SmtpClient("smtp.gmail.com", "587");
    $smtp.EnableSSL = $true;
    $smtp.Credentials = New-Object System.Net.NetworkCredential($Username, $Password);
    $smtp.send($message);
    write-host "Email odeslán $(get-date)" ; 
 }

function DO-generateReport 
    {        
        $(echo '<html> <body> <p style="text-align:center"><b> > LOG < </b></p>') *>&1 > $logfile
        
        $(echo '<br><b>INFORMACE O DISKU</b> <br>';infoDisk; echo '<br>') *>&1 >> $logfile
        $(echo '<br><b>INFORMACE O NAPÁJENÍ</b> <br>';infoBatt; echo '<br>') *>&1 >> $logfile
        $(echo '<br><b>INFORMACE O SYSTÉMU</b> <br>';infoSys; echo '<br>') *>&1 >> $logfile

        $(Write-Host "<br>OPScounter: $opscounter; Vygenerováno:" $(Get-Date);echo "</body> </html>") *>&1 >> $logfile
    }

DO
    {
        $opscounter++
        DO-generateReport
        DO-sendMail
        sleep -s 3600 #jedna hodina
    }
while ($alive -eq 1)
