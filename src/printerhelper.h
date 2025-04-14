// printerhelper.h
#ifndef PRINTERHELPER_H
#define PRINTERHELPER_H

#include <QObject>
#include <QPrinter>
#include <QPrintDialog>
#include <QString>
#include <QStringList>
#include <memory>
#include <poppler-qt6.h>
#include <QSettings>
#include <QPrinterInfo>
#include <QDir>
#include <QUrlQuery>
class PrinterHelper : public QObject
{
    Q_OBJECT

public:
    explicit PrinterHelper(QObject *parent = nullptr);

    // Original methods
    Q_INVOKABLE bool printPdf(const QString &pdfPath);
    Q_INVOKABLE bool printPdfWithPreview(const QString &pdfPath);

    // New methods for receipt printing
    Q_INVOKABLE bool printThermalReceipt(const QString &pdfPath);
    Q_INVOKABLE bool directPrintReceipt(const QString &pdfPath, const QString &printerName = QString());

    // Configuration methods
    Q_INVOKABLE void setColorMode(bool color);
    Q_INVOKABLE void setCopyCount(int count);
    Q_INVOKABLE void setDuplex(bool enabled);
    Q_INVOKABLE void setPrinterName(const QString &printerName);
    Q_INVOKABLE     void setCustomPaperSize(qreal widthMM, bool autoHeight = true, qreal customHeightMM = 0);
    Q_INVOKABLE void setZoom(qreal zoomFactor);
    Q_INVOKABLE QStringList getPrinterNames() const;
    Q_INVOKABLE bool savePrinterConfig(const QString &configName, const QVariantMap &config);
    Q_INVOKABLE QVariantMap loadPrinterConfig(const QString &configName) const;
    Q_INVOKABLE bool saveReceiptAsPdf(const QString &sourcePdfPath, const QString &outputPdfPath);
    Q_INVOKABLE bool renderDocumentWithOriginalSize(const std::unique_ptr<Poppler::Document>& document, QPrinter* printer);
    Q_INVOKABLE bool printThermalReceiptWithSettings(const QString &pdfPath,
                                                    const QString &configName = QStringLiteral("ReceiptPrinting"));
    bool setReceiptWidth(bool useWideReceipt, const QString &heightOption = QStringLiteral("medium"));
    Q_INVOKABLE bool printReceiptWithConfig(const QString &pdfUrl,
                                            const QString &configName = QStringLiteral("ReceiptPrinting"));
    int findLastContentRow(const QImage &image);
    Q_INVOKABLE void setPositionOffset(int x, int y) {
        xOffset = x;
        yOffset = y;
    }

    Q_INVOKABLE void resetPositionOffset() {
        xOffset = 0;
        yOffset = 0;
    }
private:
    QPrinter printer;


    bool setupPrinter(const QString &pdfPath);
    QString normalizeFilePath(const QString &path);
    bool renderDocument(const std::unique_ptr<Poppler::Document>& document, QPrinter* printer);
        bool renderDocumentToPainter(Poppler::Document* document, QPainter* painter, QPrinter* printer);
    qreal zoomFactor = 1.0;
    int xOffset = 0;
    int yOffset = 0;


};

#endif // PRINTERHELPER_H
