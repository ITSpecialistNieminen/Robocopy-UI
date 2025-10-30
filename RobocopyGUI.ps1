<#
.SYNOPSIS
    GUI wrapper for Robocopy with selectable parameters and real-time output.

.DESCRIPTION
    This script provides a Windows Presentation Framework (WPF) GUI for 
    Microsoft Robocopy. Users can select source and destination folders,
    file masks, logging, multithreading, retry counts, wait times, and
    additional Robocopy options using checkboxes. The script shows a 
    confirmation prompt with the full command and displays real-time
    output in a separate window.

.PARAMETER Source
    Source directory path to copy from.

.PARAMETER Destination
    Destination directory path to copy to.

.PARAMETER Filemask
    File pattern(s) to copy. Default is '*.*'.

.PARAMETER MT
    Multithreading. Specify 1–128 threads.

.PARAMETER R
    Number of retries on failed copies.

.PARAMETER W
    Wait time (in seconds) between retries.

.PARAMETER LOG
    Path to log file. Enable to log output.

.PARAMETER RobocopyOptions
    Various additional options like /MIR, /E, /Z, /MOV, /TEE, etc.

.EXAMPLE
    .\RobocopyGUI.ps1

    Opens the GUI window. The user selects options, clicks 'Run', confirms
    the Robocopy command, and watches the copy progress in the output window.

.NOTES
    Author: Petri Nieminen
    Created: 2025-10-29
    Requires: PowerShell 5+ (WPF support)

#>

# Load WPF assemblies
Add-Type -AssemblyName PresentationFramework

# --- XAML definition for the GUI window ---
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Robocopy GUI" Height="650" Width="650"
        ResizeMode="CanResizeWithGrip"
        WindowStartupLocation="CenterScreen">

    <!-- Root grid with rows for inputs, checkboxes, and buttons -->
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/> <!-- Top options -->
            <RowDefinition Height="*"/>    <!-- Scrollable checkboxes -->
            <RowDefinition Height="Auto"/> <!-- Buttons -->
        </Grid.RowDefinitions>

        <!-- Top input section -->
        <Grid Grid.Row="0" Margin="0,0,0,10">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/> <!-- Source -->
                <RowDefinition Height="Auto"/> <!-- Destination -->
                <RowDefinition Height="Auto"/> <!-- Filemask + LOG -->
                <RowDefinition Height="Auto"/> <!-- /MT -->
                <RowDefinition Height="Auto"/> <!-- /R -->
                <RowDefinition Height="Auto"/> <!-- /W -->
            </Grid.RowDefinitions>
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/> <!-- Label -->
                <ColumnDefinition Width="Auto"/> <!-- Input box / StackPanel -->
                <ColumnDefinition Width="Auto"/> <!-- Label2 -->
                <ColumnDefinition Width="*"/>    <!-- Input box + checkbox -->
            </Grid.ColumnDefinitions>

            <!-- Source -->
            <TextBlock Grid.Row="0" Grid.Column="0" Text="Source:" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,5,5"/>
            <TextBox Grid.Row="0" Grid.Column="1" Grid.ColumnSpan="3" Name="txtSource" Height="26" Margin="0,0,0,5"/>

            <!-- Destination -->
            <TextBlock Grid.Row="1" Grid.Column="0" Text="Destination:" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,5,5"/>
            <TextBox Grid.Row="1" Grid.Column="1" Grid.ColumnSpan="3" Name="txtDest" Height="26" Margin="0,0,0,5"/>

            <!-- Filemask + LOG -->
            <TextBlock Grid.Row="2" Grid.Column="0" Text="Filemask:" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,5,0"/>
            <TextBox Grid.Row="2" Grid.Column="1" Name="txtMask" Width="120" Height="24" Text="*.*" IsEnabled="False"/>
            <TextBlock Grid.Row="2" Grid.Column="2" Text="/LOG:" FontWeight="Bold" VerticalAlignment="Center" Margin="15,0,5,0"/>
            <StackPanel Grid.Row="2" Grid.Column="3" Orientation="Horizontal">
                <TextBox Name="txtLOGValue" Width="250" Height="24" Text="C:\temp\robocopy.log" IsEnabled="False"/>
                <CheckBox Name="chkLOG" Content="Enable" Margin="10,0,0,0" VerticalAlignment="Center"/>
            </StackPanel>

            <!-- /MT -->
            <TextBlock Grid.Row="3" Grid.Column="0" Text="/MT:" FontWeight="Bold" Margin="0,0,5,5" VerticalAlignment="Center"/>
            <StackPanel Grid.Row="3" Grid.Column="1" Orientation="Horizontal" Margin="0,0,0,5" Grid.ColumnSpan="3">
                <TextBox Name="txtMTValue" Width="50" Height="24" Text="8" IsEnabled="False"/>
                <TextBlock Text="threads" VerticalAlignment="Center" Margin="5,0,0,0"/>
                <CheckBox Name="chkMT" Content="Enable" Margin="10,0,0,0" VerticalAlignment="Center"/>
            </StackPanel>

            <!-- /R -->
            <TextBlock Grid.Row="4" Grid.Column="0" Text="/R:" FontWeight="Bold" Margin="0,0,5,5" VerticalAlignment="Center"/>
            <StackPanel Grid.Row="4" Grid.Column="1" Orientation="Horizontal" Margin="0,0,0,5" Grid.ColumnSpan="3">
                <TextBox Name="txtRValue" Width="50" Height="24" Text="3" IsEnabled="False"/>
                <TextBlock Text="retries" VerticalAlignment="Center" Margin="5,0,0,0"/>
                <CheckBox Name="chkR" Content="Enable" Margin="10,0,0,0" VerticalAlignment="Center"/>
            </StackPanel>

            <!-- /W -->
            <TextBlock Grid.Row="5" Grid.Column="0" Text="/W:" FontWeight="Bold" Margin="0,0,5,5" VerticalAlignment="Center"/>
            <StackPanel Grid.Row="5" Grid.Column="1" Orientation="Horizontal" Margin="0,0,0,5" Grid.ColumnSpan="3">
                <TextBox Name="txtWValue" Width="50" Height="24" Text="5" IsEnabled="False"/>
                <TextBlock Text="seconds" VerticalAlignment="Center" Margin="5,0,0,0"/>
                <CheckBox Name="chkW" Content="Enable" Margin="10,0,0,0" VerticalAlignment="Center"/>
            </StackPanel>
        </Grid>

        <!-- Scrollable options checkboxes -->
        <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" Margin="0,0,0,10">
            <UniformGrid Columns="2">
                <CheckBox Name="chkMIR" Content="/MIR - Mirror source to destination"/>
                <CheckBox Name="chkE" Content="/E - Copy subdirs (incl. empty)"/>
                <CheckBox Name="chkS" Content="/S - Copy subdirs (exclude empty)"/>
                <CheckBox Name="chkZ" Content="/Z - Restartable mode"/>
                <CheckBox Name="chkZB" Content="/ZB - Use restartable, fallback to Backup mode"/>
                <CheckBox Name="chkXO" Content="/XO - Exclude older files"/>
                <CheckBox Name="chkXC" Content="/XC - Exclude changed files"/>
                <CheckBox Name="chkXN" Content="/XN - Exclude newer files"/>
                <CheckBox Name="chkMOV" Content="/MOV - Move files only"/>
                <CheckBox Name="chkMOVE" Content="/MOVE - Move files and dirs"/>
                <CheckBox Name="chkPURGE" Content="/PURGE - Delete dest files not in source"/>
                <CheckBox Name="chkCOPYALL" Content="/COPYALL - Copy all file info"/>
                <CheckBox Name="chkSEC" Content="/SEC - Copy security info"/>
                <CheckBox Name="chkDCOPY" Content="/DCOPY:T - Copy directory timestamps"/>
                <CheckBox Name="chkTEE" Content="/TEE - Output to console and log"/>
                <CheckBox Name="chkNFL" Content="/NFL - No file list"/>
                <CheckBox Name="chkNDL" Content="/NDL - No directory list"/>
                <CheckBox Name="chkNP" Content="/NP - No progress"/>
                <CheckBox Name="chkNS" Content="/NS - No size info"/>
                <CheckBox Name="chkNC" Content="/NC - No class info"/>
                <CheckBox Name="chkETA" Content="/ETA - Show estimated time of arrival"/>
            </UniformGrid>
        </ScrollViewer>

        <!-- Action buttons -->
        <StackPanel Orientation="Horizontal" Grid.Row="2" HorizontalAlignment="Right">
            <Button Name="btnInfo" Content="Info" Width="100" Margin="5"/>
            <Button Name="btnRun" Content="Run" Width="100" Margin="5"/>
            <Button Name="btnClose" Content="Close" Width="100" Margin="5"/>
        </StackPanel>

    </Grid>
</Window>
"@

# --- Load XAML ---
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$Window = [Windows.Markup.XamlReader]::Load($reader)

# --- Dynamically create variables for all named controls ---
$xaml.SelectNodes("//*[@Name]") | ForEach-Object {
    Set-Variable -Name ($_.Name) -Value $Window.FindName($_.Name)
}

# --- Enable/Disable textboxes based on Enable checkboxes ---
$txtMTValue.IsEnabled  = $false
$txtRValue.IsEnabled   = $false
$txtWValue.IsEnabled   = $false
$txtLOGValue.IsEnabled = $false

$chkMT.Add_Checked({ $txtMTValue.IsEnabled  = $true })
$chkMT.Add_Unchecked({ $txtMTValue.IsEnabled = $false })

$chkR.Add_Checked({ $txtRValue.IsEnabled  = $true })
$chkR.Add_Unchecked({ $txtRValue.IsEnabled = $false })

$chkW.Add_Checked({ $txtWValue.IsEnabled  = $true })
$chkW.Add_Unchecked({ $txtWValue.IsEnabled = $false })

$chkLOG.Add_Checked({ $txtLOGValue.IsEnabled  = $true })
$chkLOG.Add_Unchecked({ $txtLOGValue.IsEnabled = $false })

# --- Close button ---
$btnClose.Add_Click({ $Window.Close() })

# --- Info button ---
$btnInfo.Add_Click({
    $infoText = @"
/MT    - Enables multithreading (1–128 threads).
/R     - Number of retries on failed copies.
/W     - Wait time (in seconds) between retries.
/LOG   - Path to log file.

/MIR   - Mirror source to destination.
/E     - Copy all subdirectories, including empty.
/S     - Copy subdirectories, excluding empty.
/Z     - Restartable mode.
/ZB    - Use restartable, fallback to Backup mode.
/XO    - Exclude older files.
/XC    - Exclude changed files.
/XN    - Exclude newer files.
/MOV   - Move files only.
/MOVE  - Move files and directories.
/PURGE - Delete destination files not in source.
/COPYALL - Copy all file info (data, attributes, timestamps, security, owner, audit).
/SEC    - Copy security info.
/DCOPY:T - Copy directory timestamps.
/TEE    - Output to console and log.
/NFL    - No file list.
/NDL    - No directory list.
/NP     - No progress.
/NS     - No size info.
/NC     - No class info.
/ETA    - Show estimated time of arrival.
"@

    [System.Windows.MessageBox]::Show(
        $infoText,
        "Robocopy Parameter Info",
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Information
    )
})

# --- Run button ---
$btnRun.Add_Click({
    # Gather inputs
    $src = $txtSource.Text
    $dst = $txtDest.Text
    $mask = if ($txtMask.Text) { $txtMask.Text } else { "*.*" }

    # Build Robocopy arguments
    $argsList = @()
    if ($chkMT.IsChecked)  { $argsList += "/MT:$($txtMTValue.Text)" }
    if ($chkR.IsChecked)   { $argsList += "/R:$($txtRValue.Text)" }
    if ($chkW.IsChecked)   { $argsList += "/W:$($txtWValue.Text)" }
    if ($chkLOG.IsChecked) { $argsList += "/LOG:`"$($txtLOGValue.Text)`"" }

    $checkboxes = @($chkMIR,$chkE,$chkS,$chkZ,$chkZB,$chkXO,$chkXC,$chkXN,$chkMOV,$chkMOVE,
                    $chkPURGE,$chkCOPYALL,$chkSEC,$chkDCOPY,$chkTEE,$chkNFL,$chkNDL,$chkNP,$chkNS,$chkNC,$chkETA)
    foreach ($chk in $checkboxes) {
        if ($chk.IsChecked) { $argsList += $chk.Content.Split(' ')[0] }
    }

    # Compose full command line
    $cmdline = "robocopy `"$src`" `"$dst`" $mask " + ($argsList -join ' ')

    # Prompt user before execution
    $result = [System.Windows.MessageBox]::Show(
        "Run the following command?" + "`n`n" + $cmdline,
        "Confirm Execution",
        [System.Windows.MessageBoxButton]::OKCancel,
        [System.Windows.MessageBoxImage]::Question
    )
    if ($result -ne [System.Windows.MessageBoxResult]::OK) { return }

    # Create output window
    $outputWindowXaml = @"
<Window xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation'
        Title='Robocopy Output' Height='400' Width='700'>
    <Grid Margin='5'>
        <TextBox Name='txtOutput' FontFamily='Consolas' FontSize='12'
                 VerticalScrollBarVisibility='Auto'
                 HorizontalScrollBarVisibility='Auto'
                 IsReadOnly='True' TextWrapping='NoWrap'/>
    </Grid>
</Window>
"@
    $reader = (New-Object System.Xml.XmlNodeReader ([xml]$outputWindowXaml))
    $outputWindow = [Windows.Markup.XamlReader]::Load($reader)
    $txtOutput = $outputWindow.FindName("txtOutput")
    $outputWindow.Show()

    # Start Robocopy process
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "robocopy.exe"
    $psi.Arguments = "$src $dst $mask " + ($argsList -join ' ')
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi
    $proc.Start() | Out-Null

    # Read output line by line
    while (-not $proc.HasExited) {
        while (-not $proc.StandardOutput.EndOfStream) {
            $line = $proc.StandardOutput.ReadLine()
            $txtOutput.Dispatcher.Invoke([action]{ $txtOutput.AppendText($line + "`n") })
        }
        Start-Sleep -Milliseconds 100
    }

    # Flush any remaining output
    while (-not $proc.StandardOutput.EndOfStream) {
        $line = $proc.StandardOutput.ReadLine()
        $txtOutput.Dispatcher.Invoke([action]{ $txtOutput.AppendText($line + "`n") })
    }

    # Also read error output
    while (-not $proc.StandardError.EndOfStream) {
        $line = $proc.StandardError.ReadLine()
        $txtOutput.Dispatcher.Invoke([action]{ $txtOutput.AppendText("ERR: $line`n") })
    }

    $txtOutput.Dispatcher.Invoke([action]{ $txtOutput.AppendText("=== Finished ===`n") })
})

# --- Show the window ---
$Window.ShowDialog() | Out-Null 
