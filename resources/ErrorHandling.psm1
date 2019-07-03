function Get-NewErrorHandling($errorSubject, $errorBody){
    return [ErrorHandling]::new($errorSubject, $errorBody)
}

class ErrorHandling {

    [String] $recipient = "hiestand@dinotronic.ch"
    [String] $sender = "tech@dinotronic.ch"
    [String] $smtpSender = "dtcpsmg.hostedbusiness.ch"
    [String] $errorSubject
    $errorBody 

    ErrorHandling([String] $errorSubject, $errorBody){
        $this.errorSubject = $errorSubject
        $this.errorBody = $errorBody
        $this.sendMailwithErrorMsgWithLastErrorContent()
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
}
