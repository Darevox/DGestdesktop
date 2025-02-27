// printerhelper.cpp
#include "printerhelper.h"
#include <QPrinter>
#include <QPrintDialog>
#include <QPrintPreviewDialog>
#include <QFileInfo>
#include <QPainter>
#include <QDebug>
#include <QUrl>

PrinterHelper::PrinterHelper(QObject *parent)
    : QObject(parent)
{
    // Initialize printer with high resolution
    printer.setResolution(1200);
    printer.setColorMode(QPrinter::Color);
    printer.setDuplex(QPrinter::DuplexNone);
}

// QString PrinterHelper::normalizeFilePath(const QString &path)
// {
//     QString filePath = path;
//     if (filePath.startsWith(QStringLiteral("file:///"))) {
//         filePath = filePath.mid(8);
//     }
//     if (!filePath.startsWith(QStringLiteral("/"))) {
//         filePath = QStringLiteral("/%1").arg(filePath);
//     }
//     return filePath;

// }
QString PrinterHelper::normalizeFilePath(const QString &path)
{

    QString filePath = path;

       // Remove file:// or file:/// prefix
       if (filePath.startsWith(QStringLiteral("file://"))) {
           filePath = QUrl(filePath).toLocalFile();
       }

       return filePath;
}
bool PrinterHelper::setupPrinter(const QString &pdfPath)
{
    QString filePath = normalizeFilePath(pdfPath);

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

bool PrinterHelper::renderDocument(const std::unique_ptr<Poppler::Document>& document, QPrinter* printer)
{
    if (!document) return false;

    QPainter painter;
    if (!painter.begin(printer)) {
        qWarning() << "Failed to initialize painter";
        return false;
    }

    // Print each page
    for (int i = 0; i < document->numPages(); ++i) {
        if (i > 0) {
            printer->newPage();
        }

        // Get the page
        std::unique_ptr<Poppler::Page> page(document->page(i));
        if (!page) {
            qWarning() << "Failed to get page" << i;
            continue;
        }

        // Calculate proper resolution
        QSizeF pageSize = page->pageSizeF();
        qreal scale = printer->resolution() / 72.0; // Convert from points to device pixels

        // Calculate scaled size
        QSize targetSize(
            qRound(pageSize.width() * scale),
            qRound(pageSize.height() * scale)
        );

        // Render page
        QImage image = page->renderToImage(printer->resolution(), printer->resolution());
        if (image.isNull()) {
            qWarning() << "Failed to render page" << i;
            continue;
        }

        // Calculate positioning to center the page
        QRect printerRect = printer->pageRect(QPrinter::DevicePixel).toRect();
        QRect imageRect(QPoint(0, 0), image.size());
        imageRect.moveCenter(printerRect.center());

        // Draw the page
        painter.drawImage(imageRect, image);
    }

    painter.end();
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
    QString filePath = normalizeFilePath(pdfPath);
    std::unique_ptr<Poppler::Document> document(Poppler::Document::load(filePath));

    if (!document || document->isLocked()) {
        qWarning() << "Failed to load PDF document";
        return false;
    }

    // Set up document for rendering
    document->setRenderHint(Poppler::Document::Antialiasing);
    document->setRenderHint(Poppler::Document::TextAntialiasing);

    return renderDocument(document, &printer);
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
        QString filePath = normalizeFilePath(pdfPath);

        std::unique_ptr<Poppler::Document> document(Poppler::Document::load(filePath));
        if (!document || document->isLocked()) {
            qWarning() << "Failed to load PDF for preview";
            return;
        }

        // Set up document for rendering
        document->setRenderHint(Poppler::Document::Antialiasing);
        document->setRenderHint(Poppler::Document::TextAntialiasing);

        renderDocument(document, previewPrinter);
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
