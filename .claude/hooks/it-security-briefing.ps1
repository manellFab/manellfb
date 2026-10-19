# SessionStart hook: 10 seconds after a Claude Code session starts, pop up a
# dialog announcing the mandatory IT security briefing.
# The hook returns immediately; a detached hidden process waits and shows the dialog.
param([switch]$Show)

if ($Show) {
    Start-Sleep -Seconds 5
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show(
        "There is an IT security briefing at Town Hall on Wednesday at 10:00 AM.`n`nAttendance is mandatory.",
        "IT Security Briefing",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning,
        [System.Windows.Forms.MessageBoxDefaultButton]::Button1
    ) | Out-Null

    # Follow-up prompt with a tone once the briefing notice is dismissed.
    [System.Media.SystemSounds]::Asterisk.Play()
    [console]::Beep(880, 300)
    [console]::Beep(1175, 400)
    # Buttons: Yes = Contact IT, No = Briefing details, Cancel = Dismiss.
    $itEmail = "it-help@yourcompany.com"
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Assistant"
    $form.Size = New-Object System.Drawing.Size(420, 170)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.TopMost = $true

    $label = New-Object System.Windows.Forms.Label
    $label.Text = "How can I help you?"
    $label.Font = New-Object System.Drawing.Font("Segoe UI", 12)
    $label.AutoSize = $true
    $label.Location = New-Object System.Drawing.Point(20, 20)
    $form.Controls.Add($label)

    function Add-Button($text, $x, $result) {
        $b = New-Object System.Windows.Forms.Button
        $b.Text = $text
        $b.Size = New-Object System.Drawing.Size(120, 30)
        $b.Location = New-Object System.Drawing.Point($x, 75)
        $b.DialogResult = $result
        $form.Controls.Add($b)
    }
    Add-Button "Contact IT" 20 ([System.Windows.Forms.DialogResult]::Yes)
    Add-Button "Briefing details" 150 ([System.Windows.Forms.DialogResult]::No)
    Add-Button "Dismiss" 280 ([System.Windows.Forms.DialogResult]::Cancel)
    $form.CancelButton = $form.Controls | Where-Object { $_.Text -eq "Dismiss" }

    $choice = $form.ShowDialog()
    if ($choice -eq [System.Windows.Forms.DialogResult]::Yes) {
        Start-Process "mailto:$itEmail?subject=IT%20support%20request"
    } elseif ($choice -eq [System.Windows.Forms.DialogResult]::No) {
        [System.Windows.Forms.MessageBox]::Show(
            "There is an IT security briefing at Town Hall on Wednesday at 10:00 AM.`n`nAttendance is mandatory.",
            "IT Security Briefing",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
    }
    exit 0
}

# Launch through WMI so the child is not part of the hook's process tree/job;
# otherwise Claude Code can kill it as soon as the hook itself returns.
$cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`" -Show"
Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = $cmd } | Out-Null
exit 0
