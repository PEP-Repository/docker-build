function Controller() {
    installer.autoRejectMessageBoxes();
    installer.setMessageBoxAutomaticAnswer( "OverwriteTargetDirectory", QMessageBox.Yes);
    installer.setMessageBoxAutomaticAnswer( "stopProcessesForUpdates", QMessageBox.Ignore);

    installer.installationFinished.connect(function() {
        gui.clickButton(buttons.CommitButton);
    })
}

Controller.prototype.IntroductionPageCallback = function() {
    gui.clickButton(buttons.NextButton);
}

Controller.prototype.TargetDirectoryPageCallback = function()
{
    gui.currentPageWidget().TargetDirectoryLineEdit.setText("/opt/QtIFW");
    gui.clickButton(buttons.NextButton);
}

Controller.prototype.LicenseAgreementPageCallback = function() {
    gui.currentPageWidget().AcceptLicenseRadioButton.setChecked(true);
    gui.clickButton(buttons.NextButton);
}

Controller.prototype.ReadyForInstallationPageCallback = function()
{
    gui.clickButton(buttons.CommitButton);
}

Controller.prototype.PerformInstallationPageCallback = function()
{
}

Controller.prototype.FinishedPageCallback = function()
{
    gui.clickButton(buttons.FinishButton);
}

