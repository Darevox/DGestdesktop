#pragma once

#include <QObject>
#include <QString>

class UpdateHelper : public QObject
{
    Q_OBJECT

public:
    explicit UpdateHelper(QObject* parent = nullptr);
    ~UpdateHelper();

public Q_SLOTS:
    bool extractAndUpdate(const QString& zipFilePath);

Q_SIGNALS:
    void updateProgress(int percent);
    void updateFinished(bool success);
    void updateError(const QString& error);

private:
    bool closeApplication();
    bool extractZipFile(const QString& zipFilePath, const QString& extractPath);
    bool replaceApplicationFiles(const QString& sourcePath);
    bool restartApplication();
};
