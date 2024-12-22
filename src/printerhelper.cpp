// printer_helper.cpp
#include "printerhelper.h"
#include <QPrinter>
#include <QPrintDialog>
#include <QPrintPreviewDialog>
#include <QFileInfo>
#include <QPdfDocument>
#include <QPainter>
#include <QDebug>

PrinterHelper::PrinterHelper(QObject *parent)
    : QObject(parent)
{
    // Initialize printer with high resolution
    printer.setResolution(1200);
    printer.setColorMode(QPrinter::Color);
    printer.setDuplex(QPrinter::DuplexNone);
}

bool PrinterHelper::setupPrinter(const QString &pdfPath)
{
    // Remove file:/// if present
    QString filePath = pdfPath;
       if (filePath.startsWith("file:///")) {
           filePath = filePath.mid(8);
       }
       if (!filePath.startsWith("/")) {
           filePath = "/" + filePath;
       }
    // Check if file exists
    QFileInfo fileInfo(filePath);
    if (!fileInfo.exists()) {
        qWarning() << "PDF file does not exist:" << filePath;
        return false;
    }

    // Set document name from file name
    printer.setDocName(fileInfo.fileName());

    return true;
}

bool PrinterHelper::printPdf(const QString &pdfPath)
{
    if (!setupPrinter(pdfPath)) {
        return false;
    }

    // Show print dialog
    QPrintDialog printDialog(&printer);
    if (printDialog.exec() != QDialog::Accepted) {
        return false;
    }

    // Load PDF document
    QPdfDocument document;
    QString filePath = pdfPath;
    if (filePath.startsWith("file:///")) {
        filePath = filePath.mid(8);
    }

    if (document.load(filePath) != QPdfDocument::Error::None) {
        qWarning() << "Failed to load PDF document";
        return false;
    }

    // Print document
    QPainter painter;
    if (!painter.begin(&printer)) {
        qWarning() << "Failed to initialize painter";
        return false;
    }

    // Print each page
    for (int i = 0; i < document.pageCount(); ++i) {
        if (i > 0) {
            printer.newPage();
        }

        // Get page size and render at proper resolution
        QSizeF pageSize = document.pagePointSize(i);
        qreal scale = printer.resolution() / 72.0; // Convert from points to device pixels

        // Calculate scaled size
        QSize targetSize(
                    qRound(pageSize.width() * scale),
                    qRound(pageSize.height() * scale)
                    );

        // Render page
        QImage image = document.render(i, targetSize);
        if (image.isNull()) {
            qWarning() << "Failed to render page" << i;
            continue;
        }

        // Calculate positioning to center the page
        QRect printerRect = printer.pageRect(QPrinter::DevicePixel).toRect();
        QRect imageRect(QPoint(0, 0), image.size());
        imageRect.moveCenter(printerRect.center());

        // Draw the page
        painter.drawImage(imageRect, image);
    }

    painter.end();
    return true;
}

bool PrinterHelper::printPdfWithPreview(const QString &pdfPath)
{
    if (!setupPrinter(pdfPath)) {
        return false;
    }

    QPrintPreviewDialog preview(&printer);

    // Connect preview paint request to lambda that renders the PDF
    connect(&preview, &QPrintPreviewDialog::paintRequested,
            [this, pdfPath](QPrinter *previewPrinter) {
        QString filePath = pdfPath;
        if (filePath.startsWith("file:///")) {
            filePath = filePath.mid(8);
        }
        if (!filePath.startsWith("/")) {
            filePath = "/" + filePath;
        }

        QPdfDocument document;
        if (document.load(filePath) != QPdfDocument::Error::None) {
            qWarning() << "Failed to load PDF for preview";
            return;
        }

        QPainter painter(previewPrinter);
        for (int i = 0; i < document.pageCount(); ++i) {
            if (i > 0) {
                previewPrinter->newPage();
            }

            QSizeF pageSize = document.pagePointSize(i);
            qreal scale = previewPrinter->resolution() / 72.0;

            QSize targetSize(
                        qRound(pageSize.width() * scale),
                        qRound(pageSize.height() * scale)
                        );

            QImage image = document.render(i, targetSize);
            if (!image.isNull()) {
                QRect printerRect = previewPrinter->pageRect(QPrinter::DevicePixel).toRect();
                QRect imageRect(QPoint(0, 0), image.size());
                imageRect.moveCenter(printerRect.center());
                painter.drawImage(imageRect, image);
            }
        }
    });

    return preview.exec() == QDialog::Accepted;
}

void PrinterHelper::setColorMode(bool color)
{
    printer.setColorMode(color ? QPrinter::Color : QPrinter::GrayScale);
}

void PrinterHelper::setCopyCount(int count)
{
    printer.setCopyCount(count);
}

void PrinterHelper::setDuplex(bool enabled)
{
    printer.setDuplex(enabled ? QPrinter::DuplexAuto : QPrinter::DuplexNone);
}

void PrinterHelper::setPrinterName(const QString &printerName)
{
    printer.setPrinterName(printerName);
}
