function Get-NewErrorHandling{
    Param(
    [Parameter(Mandatory=$true, Position=0)]
    [String]$errorSubject,
    [Parameter(Mandatory=$false, Position=1)]
    $errorBody
    )
    if ($errorBody){
        return [ErrorHandling]::new($errorSubject, $errorBody)
    } else {
        return [ErrorHandling]::new($errorSubject)
    }
}

class ErrorHandling {

    [String] $recipient = "helpdesk@dinotronic.ch"
    [String] $sender = "tech@dinotronic.ch"
    [String] $smtpSender = "dtcpsmg.hostedbusiness.ch"
    [String] $errorSubject
    $errorBody 

    ErrorHandling([String] $errorSubject, $errorBody){
        $this.errorSubject = $errorSubject
        $this.errorBody = $errorBody
        $this.sendMailwithErrorMsgWithLastErrorContent()
    }

    ErrorHandling([String] $errorSubject){
        $this.errorSubject = $errorSubject
    }

    sendMailwithErrorMsgWithLastErrorContent(){
        $body += "<h2>DT CSP Data Sync Service Error</h2>"
        $body += "<h3>Details:</h3>"
        $body += "<ul>"
        $body += $this.errorBody.ToString()
        $body += "</ul>"
        Send-MailMessage -To $this.recipient -From $this.sender -Subject `
        $this.errorSubject -BodyAsHtml $body -SmtpServer $this.smtpSender
    }

    sendMailwithInformMsgContent($errorBody){
        $body += "<h2>DT CSP Data Sync Service Xflex Update Summary</h2>"
        $body += "<h3>Details:</h3>"
        $body += "<ul>"
        $body += $errorBody
        $body += "</ul>"
        Send-MailMessage -To $this.recipient -From $this.sender -Subject `
        $this.errorSubject -BodyAsHtml $body -SmtpServer $this.smtpSender
    }
}
