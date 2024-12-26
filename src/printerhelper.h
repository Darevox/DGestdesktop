// printerhelper.h
#ifndef PRINTERHELPER_H
#define PRINTERHELPER_H

#include <QObject>
#include <QPrinter>
#include <QPrintDialog>
#include <QString>
#include <memory>
#include <poppler-qt6.h>

class PrinterHelper : public QObject
{
    Q_OBJECT

public:
    explicit PrinterHelper(QObject *parent = nullptr);

    Q_INVOKABLE bool printPdf(const QString &pdfPath);
    Q_INVOKABLE bool printPdfWithPreview(const QString &pdfPath);

    // Additional configuration methods
    Q_INVOKABLE void setColorMode(bool color);
    Q_INVOKABLE void setCopyCount(int count);
    Q_INVOKABLE void setDuplex(bool enabled);
    Q_INVOKABLE void setPrinterName(const QString &printerName);

private:
    QPrinter printer;
    bool setupPrinter(const QString &pdfPath);
    QString normalizeFilePath(const QString &path);
    bool renderDocument(const std::unique_ptr<Poppler::Document>& document, QPrinter* printer);
};

#endif // PRINTERHELPER_H
