#include "UpdateHelper.h"
#include <QCoreApplication>
#include <QDir>
#include <QProcess>
#include <QTemporaryDir>
#include <QFile>
#include <QTimer>
#include <QThread>

UpdateHelper::UpdateHelper(QObject* parent) : QObject(parent)
{
}

UpdateHelper::~UpdateHelper()
{
}

bool UpdateHelper::extractAndUpdate(const QString& zipFilePath)
{
    // 1. Create temporary directory for extraction
    QTemporaryDir tempDir;
    if (!tempDir.isValid()) {
        Q_EMIT updateError(QStringLiteral("Could not create temporary directory"));
        return false;
    }

    // 2. Extract the ZIP file
    Q_EMIT updateProgress(10);
    if (!extractZipFile(zipFilePath, tempDir.path())) {
        Q_EMIT updateError(QStringLiteral("Failed to extract update files"));
        return false;
    }

    // 3. Prepare for closing the application
    Q_EMIT updateProgress(40);

    // 4. Replace application files
    Q_EMIT updateProgress(60);
    QString appDirPath = QCoreApplication::applicationDirPath();
    if (!replaceApplicationFiles(tempDir.path())) {
        Q_EMIT updateError(QStringLiteral("Failed to update application files"));
        return false;
    }

    // 5. Prepare restart
    Q_EMIT updateProgress(90);

    // Close the application and restart
    closeApplication();
    QTimer::singleShot(500, [this]() {
        restartApplication();
        Q_EMIT updateProgress(100);
        Q_EMIT updateFinished(true);
    });

    return true;
}

bool UpdateHelper::closeApplication()
{
    // This will close the application
    QTimer::singleShot(500, []() {
        QCoreApplication::quit();
    });
    return true;
}

bool UpdateHelper::extractZipFile(const QString& zipFilePath, const QString& extractPath)
{
    // This is a simplified implementation - in a real app you would use
    // a ZIP library like QuaZIP

#ifdef Q_OS_WIN
    // On Windows, use PowerShell to extract zip
    QStringList args;
    args << QStringLiteral("-NoProfile") << QStringLiteral("-NonInteractive") << QStringLiteral("-Command");
    args << QStringLiteral("Expand-Archive -Path \"%1\" -DestinationPath \"%2\" -Force")
            .arg(zipFilePath, extractPath);

    QProcess process;
    process.start(QStringLiteral("powershell.exe"), args);
    process.waitForFinished();
    return (process.exitCode() == 0);
#else
    // On Linux, use unzip command
    QProcess process;
    process.start(QStringLiteral("unzip"), QStringList()
                 << QStringLiteral("-o")
                 << zipFilePath
                 << QStringLiteral("-d")
                 << extractPath);
    process.waitForFinished();
    return (process.exitCode() == 0);
#endif
}

bool UpdateHelper::replaceApplicationFiles(const QString& sourcePath)
{
    QString appDir = QCoreApplication::applicationDirPath();

    // Copy all files from the source directory to the application directory
    QDir sourceDir(sourcePath);
    QStringList files = sourceDir.entryList(QDir::Files | QDir::NoDotAndDotDot);

    for (const QString& file : files) {
        QString sourceFile = sourcePath + QStringLiteral("/") + file;
        QString destFile = appDir + QStringLiteral("/") + file;

        // Try to remove destination file if it exists
        QFile::remove(destFile);

        // Copy the new file
        if (!QFile::copy(sourceFile, destFile)) {
            return false;
        }
    }

    // Also copy subdirectories
    QStringList dirs = sourceDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
    for (const QString& dir : dirs) {
        // Create directory if it doesn't exist
        QString destDir = appDir + QStringLiteral("/") + dir;
        QDir().mkpath(destDir);

        // Recursively copy files from subdirectory
        QString sourceSubdir = sourcePath + QStringLiteral("/") + dir;
        QDir subSourceDir(sourceSubdir);
        QStringList subFiles = subSourceDir.entryList(QDir::Files | QDir::NoDotAndDotDot);

        for (const QString& file : subFiles) {
            QString sourceFile = sourceSubdir + QStringLiteral("/") + file;
            QString destFile = destDir + QStringLiteral("/") + file;

            QFile::remove(destFile);
            QFile::copy(sourceFile, destFile);
        }
    }

    return true;
}

bool UpdateHelper::restartApplication()
{
    QString appPath = QCoreApplication::applicationFilePath();
    QStringList args = QCoreApplication::arguments();
    args.removeFirst(); // Remove the executable name

    // Start a detached process to relaunch the app
    return QProcess::startDetached(appPath, args);
}
