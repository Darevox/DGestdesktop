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

// renderDocument method
bool PrinterHelper::renderDocument(const std::unique_ptr<Poppler::Document>& document, QPrinter* printer)
{
    if (!document) {
        qWarning() << "Invalid document!";
        return false;
    }

    // Get printer information
    qreal dpi = printer->resolution();
    QRect printerRect = printer->pageLayout().paintRectPixels(dpi);
    QSizeF paperSizeMM = printer->pageLayout().fullRect(QPageLayout::Millimeter).size();
    QPageLayout::Orientation orientation = printer->pageLayout().orientation();
    bool isPdfFormat = (printer->outputFormat() == QPrinter::PdfFormat);

    qDebug() << "Printer paper size (mm):" << paperSizeMM;
    qDebug() << "Printer printable area (px):" << printerRect;
    qDebug() << "Printer resolution:" << dpi << "dpi";
    qDebug() << "Printer orientation:" << (orientation == QPageLayout::Portrait ? "Portrait" : "Landscape");
    qDebug() << "Output format:" << (isPdfFormat ? "PDF" : "Printer");
    qDebug() << "Zoom factor:" << zoomFactor;
    qDebug() << "Number of pages in document:" << document->numPages();

    // Check if this appears to be a receipt printer (narrow width)
    bool isReceiptPaper = (paperSizeMM.width() <= 105); // 4 inch or less
    bool is80mmReceipt = (paperSizeMM.width() >= 79 && paperSizeMM.width() <= 81);
    bool is58mmReceipt = (paperSizeMM.width() >= 57 && paperSizeMM.width() <= 59);

    // Identify if this is a thermal printer based on name
    bool isThermalPrinter = printer->printerName().contains(QStringLiteral("XP"), Qt::CaseInsensitive) ||
                           printer->printerName().contains(QStringLiteral("Thermal"), Qt::CaseInsensitive) ||
                           printer->printerName().contains(QStringLiteral("Receipt"), Qt::CaseInsensitive) ||
                           printer->printerName().contains(QStringLiteral("POS"), Qt::CaseInsensitive);

    // Calculate thermal printer width in inches
    qreal widthInches = paperSizeMM.width() / 25.4; // Convert mm to inches
    qDebug() << "Paper width in inches:" << widthInches;

    // Set optimal paper format for thermal printers (uses standard sizes when possible)
    if (isReceiptPaper && !isPdfFormat) {
        // Pre-rendering calculation to determine content height
        qreal totalContentHeight = 0;
        int pageCount = document->numPages();

        qDebug() << "Analyzing content height across" << pageCount << "pages";

        // Calculate approximate content height by analyzing each page
        for (int i = 0; i < pageCount; ++i) {
            std::unique_ptr<Poppler::Page> page(document->page(i));
            if (!page) continue;

            QImage image = page->renderToImage(300, 300); // High resolution for detection
            if (image.isNull()) continue;

            // Scale and analyze for content height
            qreal scale = 1.0;
            if (image.width() > printerRect.width()) {
                scale = (qreal)printerRect.width() / (qreal)image.width();
            }

            // Analyze image for content height
            QImage scaledImage = image.scaled(
                qRound(image.width() * scale),
                qRound(image.height() * scale),
                Qt::IgnoreAspectRatio,
                Qt::SmoothTransformation
            );

            int lastContentRow = -1;
            for (int y = scaledImage.height() - 1; y >= 0; y--) {
                for (int x = 0; x < scaledImage.width(); x += 10) { // Sample every 10 pixels
                    if (qGray(scaledImage.pixel(x, y)) < 240) { // Non-white pixel
                        lastContentRow = y;
                        break;
                    }
                }
                if (lastContentRow >= 0) break;
            }

            if (lastContentRow >= 0) {
                totalContentHeight += (lastContentRow + 10); // Add some margin
                qDebug() << "Page" << i + 1 << "content height:" << lastContentRow + 10 << "px";
            } else {
                totalContentHeight += scaledImage.height(); // Use full height if no detection
                qDebug() << "Page" << i + 1 << "using full height:" << scaledImage.height() << "px";
            }

            // Add space between pages
            if (i > 0) totalContentHeight += 10;
        }

        // Convert content height to inches
        qreal contentHeightInches = totalContentHeight / dpi;

        // Add small margin
        contentHeightInches += 0.25; // Add 1/4 inch margin

        // Round up to nearest half inch
        contentHeightInches = ceil(contentHeightInches * 2) / 2.0;

        qDebug() << "Total content height in inches:" << contentHeightInches;

        // Account for multi-page documents - make sure we use proper height
        // For multiple pages, we need taller paper format or we need to handle page breaks
        bool isLongContent = (contentHeightInches > 4.0) || (pageCount > 1);

        // Select the best predefined size based on content and page count
        if (widthInches >= 3.5 && widthInches <= 4.5) {
            // 4-inch width receipt paper
            if (!isLongContent && contentHeightInches <= 4.0) {
                // Use 4x4 inch format for short receipts with single page
                qDebug() << "Setting paper size to 4x4 inches for short content";
                QPageSize customSize(QSizeF(4, 4), QPageSize::Inch, QStringLiteral("4x4inch"));
                printer->setPageSize(customSize);
            } else if (contentHeightInches <= 6.0) {
                // Use 4x6 inch format for medium receipts or multi-page
                qDebug() << "Setting paper size to 4x6 inches (medium or multi-page)";
                QPageSize customSize(QSizeF(4, 6), QPageSize::Inch, QStringLiteral("4x6inch"));
                printer->setPageSize(customSize);
            } else if (contentHeightInches <= 8.0) {
                // Use 4x8 for longer content
                qDebug() << "Setting paper size to 4x8 inches (longer content)";
                QPageSize customSize(QSizeF(4, 8), QPageSize::Inch, QStringLiteral("4x8inch"));
                printer->setPageSize(customSize);
            } else {
                // Use 4x11 or 4x12 for very long content
                qreal heightToUse = (contentHeightInches <= 11.0) ? 11.0 : 12.0;
                qDebug() << "Setting paper size to 4x" << heightToUse << "inches (very long content)";
                QPageSize customSize(QSizeF(4, heightToUse), QPageSize::Inch,
                                   QStringLiteral("4x%1inch").arg(heightToUse));
                printer->setPageSize(customSize);
            }
        } else if (widthInches >= 2.0 && widthInches < 3.5) {
            // Approximately 58mm/2.25 inch paper using similar logic
            if (!isLongContent && contentHeightInches <= 4.0) {
                // Use 2x4 inch format for short receipts
                qDebug() << "Setting paper size to 2x4 inches";
                QPageSize customSize(QSizeF(2.25, 4), QPageSize::Inch, QStringLiteral("2x4inch"));
                printer->setPageSize(customSize);
            } else if (contentHeightInches <= 6.0) {
                // Use 2x6 inch format for medium receipts
                qDebug() << "Setting paper size to 2x6 inches";
                QPageSize customSize(QSizeF(2.25, 6), QPageSize::Inch, QStringLiteral("2x6inch"));
                printer->setPageSize(customSize);
            } else if (contentHeightInches <= 8.0) {
                // Use 2x8 format
                qDebug() << "Setting paper size to 2x8 inches";
                QPageSize customSize(QSizeF(2.25, 8), QPageSize::Inch, QStringLiteral("2x8inch"));
                printer->setPageSize(customSize);
            } else {
                // Use taller format for longer content
                qreal heightToUse = (contentHeightInches <= 11.0) ? 11.0 : 12.0;
                qDebug() << "Setting paper size to 2x" << heightToUse << "inches";
                QPageSize customSize(QSizeF(2.25, heightToUse), QPageSize::Inch,
                                   QStringLiteral("2x%1inch").arg(heightToUse));
                printer->setPageSize(customSize);
            }
        } else {
            // Custom/unusual width - create a custom size
            qreal customWidth = widthInches;

            // For multi-page or long content, choose a taller format
            qreal customHeight;
            if (isLongContent) {
                // Use at least 6 inches for long/multi-page content or scale based on content
                customHeight = qMax(6.0, qMin(contentHeightInches, 12.0));
            } else {
                customHeight = qMin(contentHeightInches, 11.0);
            }

            qDebug() << "Setting custom paper size:" << customWidth << "x" << customHeight
                     << "inches for" << pageCount << "pages";

            QPageSize customSize(QSizeF(customWidth, customHeight), QPageSize::Inch,
                               QStringLiteral("%1x%2inch").arg(customWidth, 0, 'f', 1).arg(customHeight, 0, 'f', 1));
            printer->setPageSize(customSize);
        }

        // Force portrait orientation for receipt printers
        printer->setPageOrientation(QPageLayout::Portrait);

        // After setting paper size, check if we need to adjust QPrinter settings for multi-page
        if (pageCount > 1) {
            // Enable automatic page breaks for multi-page documents
            printer->setCollateCopies(true);

            // Check if we should use separate pages
            bool tooLong = (contentHeightInches > 11.0);
            if (tooLong && !isPdfFormat) {
                qDebug() << "Content too long (" << contentHeightInches
                         << "inches), will use multiple physical pages";
                // We'll let the renderer use multiple pages and handle page breaks
                // This is handled in the page rendering loop
            }
        }

        // Update printer rect after size change
        printerRect = printer->pageLayout().paintRectPixels(dpi);
    }

    // Calculate margin factors based on paper type
    qreal leftMarginFactor, rightMarginFactor;
    if (isReceiptPaper) {
        qDebug() << "Receipt paper detected - using special handling";
        if (is58mmReceipt) {
            leftMarginFactor = 0.03;  // 3% margin on left for 58mm
            rightMarginFactor = 0.05; // 5% margin on right for 58mm
        } else if (is80mmReceipt) {
            leftMarginFactor = 0.04;  // 4% margin on left for 80mm
            rightMarginFactor = 0.06; // 6% margin on right for 80mm
        } else {
            leftMarginFactor = 0.04;  // 4% margin on left for other receipt
            rightMarginFactor = 0.07; // 7% margin on right for other receipt
        }
    } else {
        leftMarginFactor = 0.02;  // 2% margin for regular paper
        rightMarginFactor = 0.02; // 2% margin for regular paper
    }

    // Calculate total margin factor
    qreal totalMarginFactor = leftMarginFactor + rightMarginFactor;

    // First pass for PDF output - calculate total heights
    QVector<QImage> renderedImages;
    QVector<qreal> scaleFactors;
    QVector<int> contentHeights;
    int totalContentHeight = 0;

    // For PDF output, pre-render and calculate exact content height
    if (isPdfFormat) {
        for (int i = 0; i < document->numPages(); ++i) {
            std::unique_ptr<Poppler::Page> page(document->page(i));
            if (!page) continue;

            // Render at high resolution
            QImage image = page->renderToImage(300, 300);
            if (image.isNull()) continue;

            // Calculate safe printable width and scale
            int safePrintableWidth = printerRect.width() * (1.0 - totalMarginFactor);
            qreal scaleToFit = (qreal)safePrintableWidth / (qreal)image.width();

            // Apply zoom with constraints
            qreal scale;
            if (isReceiptPaper) {
                qreal maxZoom = 0.95;
                qreal effectiveZoom = qMin(zoomFactor, maxZoom);
                scale = qMin(scaleToFit, effectiveZoom);
                scale = qMax(scale, 0.8 * scaleToFit);
            } else {
                scale = scaleToFit * zoomFactor;
            }

            // Find actual content height
            QImage scaledImage = image.scaled(
                qRound(image.width() * scale),
                qRound(image.height() * scale),
                Qt::IgnoreAspectRatio, Qt::SmoothTransformation);

            // Find last row with content
            int lastContentRow = scaledImage.height() - 1;
            bool foundContent = false;

            for (int y = scaledImage.height() - 1; y >= 0; y--) {
                bool rowHasContent = false;
                for (int x = 0; x < scaledImage.width(); x += 10) {
                    if (qGray(scaledImage.pixel(x, y)) < 235) {
                        rowHasContent = true;
                        break;
                    }
                }

                if (rowHasContent) {
                    lastContentRow = y;
                    foundContent = true;
                    break;
                }
            }

            // Use detected height or full height
            int contentHeight;
            if (foundContent) {
                contentHeight = lastContentRow + 10; // 10px buffer
                qDebug() << "PDF page" << i+1 << "content ends at row" << lastContentRow
                         << ", height =" << contentHeight << "px";
            } else {
                contentHeight = scaledImage.height();
                qDebug() << "PDF page" << i+1 << "no content detected, using full height:" << contentHeight;
            }

            // Store the rendered image, scale factor, and content height
            renderedImages.append(image);
            scaleFactors.append(scale);
            contentHeights.append(contentHeight);

            // Add to total content height
            totalContentHeight += contentHeight;

            // Add spacing between pages
            if (i > 0) totalContentHeight += 5;
        }

        // Adjust PDF paper height to match content
        if (!renderedImages.isEmpty()) {
            // Add margins
            totalContentHeight += 10; // 5px top + 5px bottom

            // Convert to PDF points (72 points/inch)
            qreal contentHeightPoints = totalContentHeight * 72.0 / dpi;

            // Get current layout and size
            QPageLayout currentLayout = printer->pageLayout();
            QPageSize currentSize = currentLayout.pageSize();

            // Create custom page size with adjusted height
            QPageSize customSize(QSizeF(currentSize.size(QPageSize::Point).width(),
                                       contentHeightPoints),
                                QPageSize::Point);

            // Apply the new page size
            QPageLayout newLayout(customSize, currentLayout.orientation(),
                                 currentLayout.margins());

            if (printer->setPageLayout(newLayout)) {
                qDebug() << "Set custom PDF height:" << contentHeightPoints << "points";
                printerRect = printer->pageLayout().paintRectPixels(dpi);
            } else {
                qWarning() << "Failed to set custom PDF height";
            }
        }
    }

    // Start painting
    QPainter painter;
    if (!painter.begin(printer)) {
        qWarning() << "Failed to initialize painter";
        return false;
    }

    // Render differently based on output format
    if (isPdfFormat && !renderedImages.isEmpty()) {
        // PDF output - use pre-rendered images with exact content heights
        int currentY = 5; // Start with small top margin

        for (int i = 0; i < renderedImages.size(); ++i) {
            if (i > 0) {
                if (!printer->newPage()) {
                    qWarning() << "Failed to create new page for PDF";
                    break;
                }
                currentY = 5; // Reset Y position for new page
            }

            // Get the rendered image and scale
            QImage &image = renderedImages[i];
            qreal scale = scaleFactors[i];

            // Calculate dimensions
            int targetWidth = qRound(image.width() * scale);
            int targetHeight = contentHeights[i]; // Use the calculated content height

            // Calculate position
            int xPos;
            if (isReceiptPaper) {
                int leftMarginPx = qRound(printerRect.width() * leftMarginFactor);
                xPos = leftMarginPx;
            } else {
                xPos = (printerRect.width() - targetWidth) / 2;
            }

            // Apply offsets
            xPos += xOffset;
            int yPos = currentY + yOffset;

            // Ensure valid positions
            xPos = qMax(0, xPos);
            yPos = qMax(0, yPos);

            // Set up target rectangle
            QRect targetRect(xPos, yPos, targetWidth, targetHeight);

            // Calculate source rectangle (only include actual content)
            int sourceHeight = qRound(targetHeight / scale);
            QRect sourceRect(0, 0, image.width(), sourceHeight);

            // Draw with high quality
            painter.save();
            painter.setRenderHint(QPainter::SmoothPixmapTransform, true);
            painter.setRenderHint(QPainter::Antialiasing, true);
            painter.drawImage(targetRect, image, sourceRect);
            painter.restore();

            // Update Y position
            currentY += targetHeight + 5; // Add small spacing
        }
    } else {
        // Standard rendering path for printer output
        for (int i = 0; i < document->numPages(); ++i) {
            if (i > 0) {
                if (!printer->newPage()) {
                    qWarning() << "Failed to create new page for page" << i+1;
                    break;
                }
            }

            // Get the page
            std::unique_ptr<Poppler::Page> page(document->page(i));
            if (!page) continue;

            // Use appropriate DPI
            qreal renderDpi = isReceiptPaper ? 300.0 : dpi;
            renderDpi = qMax(renderDpi, 150.0); // Minimum 150 DPI

            QImage image = page->renderToImage(renderDpi, renderDpi);
            if (image.isNull()) continue;

            // Calculate the safe printable width
            int safePrintableWidth = printerRect.width() * (1.0 - totalMarginFactor);

            // Calculate scale
            qreal scaleToFit = (qreal)safePrintableWidth / (qreal)image.width();
            qreal scale;

            if (isReceiptPaper) {
                qreal maxZoom = 0.95;
                qreal effectiveZoom = qMin(zoomFactor, maxZoom);
                scale = qMin(scaleToFit, effectiveZoom);
                scale = qMax(scale, 0.8 * scaleToFit);
            } else {
                scale = scaleToFit * zoomFactor;
            }

            // Calculate dimensions
            int targetWidth = qRound(image.width() * scale);
            int targetHeight = qRound(image.height() * scale);

            // For receipts, find actual content height
            int effectiveHeight = targetHeight;

            if (isReceiptPaper) {
                // Scale to identify content boundaries
                QImage scaledImage = image.scaled(
                    targetWidth, targetHeight,
                    Qt::IgnoreAspectRatio, Qt::SmoothTransformation);

                // Find last row with content
                int lastContentRow = -1;
                for (int y = scaledImage.height() - 1; y >= 0; y--) {
                    bool rowHasContent = false;
                    for (int x = 0; x < scaledImage.width(); x += 10) {
                        if (qGray(scaledImage.pixel(x, y)) < 235) {
                            rowHasContent = true;
                            break;
                        }
                    }

                    if (rowHasContent) {
                        lastContentRow = y;
                        break;
                    }
                }

                if (lastContentRow >= 0) {
                    // Add a small margin after content
                    effectiveHeight = lastContentRow + 5;
                    qDebug() << "Printer page" << i+1 << "- trimmed height from"
                             << targetHeight << "to" << effectiveHeight;
                }
            }

            // Ensure width doesn't exceed safe width
            if (targetWidth > safePrintableWidth) {
                scale = (qreal)safePrintableWidth / (qreal)image.width();
                targetWidth = safePrintableWidth;
                effectiveHeight = qRound(effectiveHeight * (safePrintableWidth / (qreal)targetWidth));
            }

            // Calculate position
            int xPos;
            if (isReceiptPaper) {
                int leftMarginPx = qRound(printerRect.width() * leftMarginFactor);
                xPos = leftMarginPx;
            } else {
                xPos = (printerRect.width() - targetWidth) / 2;
            }

            // Apply offsets
            xPos += xOffset;
            int yPos = yOffset;

            // Ensure valid positions
            xPos = qMax(0, xPos);
            yPos = qMax(0, yPos);

            // Position content
            QRect targetRect(xPos, yPos, targetWidth, effectiveHeight);

            // Calculate source rectangle to only include actual content
            QRect sourceRect(0, 0, image.width(), qRound(effectiveHeight / scale));

            // Draw with high quality
            painter.save();
            painter.setRenderHint(QPainter::SmoothPixmapTransform, true);
            painter.setRenderHint(QPainter::Antialiasing, true);
            painter.drawImage(targetRect, image, sourceRect);
            painter.restore();

            // For thermal printers, add form feed at the end of the last page
            if (isReceiptPaper && isThermalPrinter && i == document->numPages() - 1) {
                // Draw form feed/cut command at the very bottom
                painter.save();
                QFont controlFont(QStringLiteral("Courier New"), 1);
                painter.setFont(controlFont);
                painter.setPen(Qt::black);

                // Position near the end of the page
                int ffYPos = targetRect.bottom() + 5;
                painter.drawText(QRect(xPos, ffYPos, 10, 10), Qt::AlignLeft, QStringLiteral("\f"));

                // Also try to add ESC/POS cut command for thermal printers
                QString cutCmd = QString(QChar(0x1D)) + QString(QChar(0x56)) + QString(QChar(0x00));
                painter.drawText(QRect(xPos + 15, ffYPos, 10, 10), Qt::AlignLeft, cutCmd);

                painter.restore();
                qDebug() << "Added form feed and cut command at y =" << ffYPos;
            }
        }
    }

    bool result = painter.end();
    qDebug() << "Painter ended with result:" << result;
    return result;
}

// setReceiptWidth method
bool PrinterHelper::setReceiptWidth(bool useWideReceipt, const QString &heightOption)
{
    // Determine width to use (80mm = ~3.15 inches, 4 inches = 101.6mm)
    qreal widthInches = useWideReceipt ? 4.0 : 3.15;
    qreal widthMM = widthInches * 25.4;

    // Determine height based on the provided option
    qreal heightInches = 4.0; // Default

    if (heightOption == QStringLiteral("short")) {
        heightInches = 4.0;
    } else if (heightOption == QStringLiteral("medium")) {
        heightInches = 6.0;
    } else if (heightOption == QStringLiteral("long")) {
        heightInches = 8.0;
    } else if (heightOption == QStringLiteral("verylong")) {
        heightInches = 11.0;
    } else if (heightOption == QStringLiteral("roll")) {
        // Use a very tall format for continuous roll paper
        heightInches = 22.0;
    } else {
        // Try to parse a numeric height if provided (e.g., "6.5")
        bool ok = false;
        qreal customHeight = heightOption.toDouble(&ok);
        if (ok && customHeight > 0.0) {
            heightInches = customHeight;
        }
    }

    qDebug() << "Setting receipt size to" << widthInches << "x" << heightInches
             << "inches (" << widthMM << "x" << (heightInches * 25.4) << "mm)";

    // Create the appropriate page size
    QString sizeName = QStringLiteral("%1x%2inch").arg(widthInches, 0, 'f', 1).arg(heightInches, 0, 'f', 1);

    QPageSize customSize(QSizeF(widthInches, heightInches), QPageSize::Inch, sizeName);

    bool result = printer.setPageSize(customSize);
    if (!result) {
        qWarning() << "Failed to set page size, trying alternative method";
        // Try alternative method
        QPageLayout layout = printer.pageLayout();
        layout.setPageSize(customSize);
        result = printer.setPageLayout(layout);
    }

    // Force portrait orientation for receipt
    printer.setPageOrientation(QPageLayout::Portrait);

    return result;
}

// setCustomPaperSize method (updated to handle custom height)
void PrinterHelper::setCustomPaperSize(qreal widthMM, bool autoHeight, qreal customHeightMM)
{
    // Use specified height or calculate a reasonable default
    qreal heightMM;
    if (customHeightMM > 0) {
        heightMM = customHeightMM;
    } else if (autoHeight) {
        heightMM = 2000; // Very long for auto-height
    } else {
        heightMM = widthMM * 4; // Default 4:1 ratio
    }

    qDebug() << "Setting custom paper size:" << widthMM << "x" << heightMM << "mm";

    // Detect standard receipt widths
    bool is4Inch = (widthMM >= 100 && widthMM <= 102);
    bool is80mm = (widthMM >= 79 && widthMM <= 81);
    bool is58mm = (widthMM >= 57 && widthMM <= 59);

    // Create a custom page size with exact dimensions
    QPageSize customPageSize;

    // Define the name based on the size
    QString pageName;
    if (is4Inch) {
        // For 4-inch receipts, try to use standard height options
        if (heightMM >= 100 && heightMM <= 102) {
            pageName = QStringLiteral("4x4InchReceipt");
        } else if (heightMM >= 150 && heightMM <= 152) {
            pageName = QStringLiteral("4x6InchReceipt");
        } else if (heightMM >= 200 && heightMM <= 203) {
            pageName = QStringLiteral("4x8InchReceipt");
        } else {
            pageName = QStringLiteral("4InchReceipt");
        }
    } else if (is80mm) {
        // For 80mm receipts, try to use standard height options
        if (heightMM >= 100 && heightMM <= 102) {
            pageName = QStringLiteral("80mmx4InchReceipt");
        } else if (heightMM >= 150 && heightMM <= 152) {
            pageName = QStringLiteral("80mmx6InchReceipt");
        } else {
            pageName = QStringLiteral("80mmReceipt");
        }
    } else if (is58mm) {
        pageName = QStringLiteral("58mmReceipt");
    } else {
        pageName = QStringLiteral("Custom%1mm").arg(widthMM);
    }

    // Create the custom page size
    customPageSize = QPageSize(QSizeF(widthMM, heightMM), QPageSize::Millimeter, pageName);

    // Set zero margins
    QMarginsF margins(0, 0, 0, 0);

    // Create page layout with custom size
    QPageLayout customLayout = QPageLayout(customPageSize, QPageLayout::Portrait, margins);
    customLayout.setUnits(QPageLayout::Millimeter);

    // Try to apply the custom layout
    bool layoutSuccess = printer.setPageLayout(customLayout);
    qDebug() << "Setting page layout result:" << layoutSuccess;

    // If that fails, try just setting the page size
    if (!layoutSuccess) {
        bool pageSizeSuccess = printer.setPageSize(customPageSize);
        qDebug() << "Setting page size result:" << pageSizeSuccess;

        // If both fail, fall back to standard sizes
        if (!pageSizeSuccess) {
            qWarning() << "Failed to set custom dimensions, using fallback standard size";

            if (widthMM <= 65) {
                // For narrow receipts, use A5 portrait
                printer.setPageSize(QPageSize(QPageSize::A5));
                printer.setPageOrientation(QPageLayout::Portrait);
            } else if (widthMM <= 105) {
                // For medium width (4-inch), use A5 landscape
                printer.setPageSize(QPageSize(QPageSize::A5));
                printer.setPageOrientation(QPageLayout::Landscape);
            } else {
                // For wider receipts, use A4 landscape
                printer.setPageSize(QPageSize(QPageSize::A4));
                printer.setPageOrientation(QPageLayout::Landscape);
            }
        }
    }

    // Make sure we use portrait for receipts
    printer.setPageOrientation(QPageLayout::Portrait);

    // Force no margins
    printer.setFullPage(true);

    // Verify settings were applied
    QSizeF actualSize = printer.pageLayout().fullRect(QPageLayout::Millimeter).size();
    QMarginsF actualMargins = printer.pageLayout().margins(QPageLayout::Millimeter);
    QPageLayout::Orientation actualOrientation = printer.pageLayout().orientation();

    qDebug() << "Actual paper size:" << actualSize << "mm";
    qDebug() << "Actual margins:" << actualMargins << "mm";
    qDebug() << "Actual orientation:" << (actualOrientation == QPageLayout::Portrait ? "Portrait" : "Landscape");
}


// Helper method to find the last row that contains content
int PrinterHelper::findLastContentRow(const QImage &image)
{
    if (image.isNull() || image.height() < 2) {
        return -1;
    }

    // Start from bottom and scan upward
    const int height = image.height();
    const int width = image.width();
    const int threshold = 235; // Threshold for non-white (slightly lower to be more sensitive)
    const int samplesPerRow = qMax(10, width / 20); // Sample points per row
    const int sampleStep = qMax(1, width / samplesPerRow);

    for (int y = height - 1; y >= 0; y--) {
        for (int x = 0; x < width; x += sampleStep) {
            QRgb pixel = image.pixel(x, y);
            int gray = qGray(pixel);
            if (gray < threshold) {
                // Non-white pixel found, this is our last content row
                return y;
            }
        }
    }

    // If we got here, no content was found (unlikely)
    return height / 2; // Return middle as fallback
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
}
QStringList PrinterHelper::getPrinterNames() const
{
    // Get list of all available printers
    QPrinterInfo::availablePrinterNames();
    QStringList printers;

    for (const QPrinterInfo &printerInfo : QPrinterInfo::availablePrinters()) {
        printers.append(printerInfo.printerName());
    }

    return printers;
}





void PrinterHelper::setZoom(qreal zoom)
{
    zoomFactor = zoom;
}

bool PrinterHelper::savePrinterConfig(const QString &configName, const QVariantMap &config)
{
    QSettings settings(QStringLiteral("Dervox"), QStringLiteral("DGest"));

    // Save to a specific group based on configName
    settings.beginGroup(QStringLiteral("PrinterConfigs/%1").arg(configName));

    for (auto it = config.constBegin(); it != config.constEnd(); ++it) {
        settings.setValue(it.key(), it.value());
    }

    settings.endGroup();
    return true;
}

QVariantMap PrinterHelper::loadPrinterConfig(const QString &configName) const
{
    QSettings settings(QStringLiteral("Dervox"), QStringLiteral("DGest"));
    QVariantMap config;

    // Load from a specific group based on configName
    settings.beginGroup(QStringLiteral("PrinterConfigs/%1").arg(configName));

    // Use range-based for loop
    for (const QString &key : settings.childKeys()) {
        config[key] = settings.value(key);
    }

    settings.endGroup();
    return config;
}

bool PrinterHelper::saveReceiptAsPdf(const QString &sourcePdfPath, const QString &outputPdfPath)
{
    QString filePath = normalizeFilePath(sourcePdfPath);
    QFileInfo fileInfo(filePath);

    if (!fileInfo.exists()) {
        qWarning() << "Source PDF file does not exist:" << filePath;
        return false;
    }

    // Make sure we have an output path and convert it to a local file path
    QString outputPath;
    if (outputPdfPath.isEmpty()) {
        // Generate default output path if none provided
        outputPath = QDir::homePath() + QDir::separator() +
                     QStringLiteral("receipt_") + QDateTime::currentDateTime().toString(QStringLiteral("yyyyMMdd_hhmmss")) + QStringLiteral(".pdf");
    } else {
        // Convert URL to local file path if needed
        if (outputPdfPath.startsWith(QStringLiteral("file://"))) {
            QUrl url(outputPdfPath);
            outputPath = url.toLocalFile();
        } else {
            outputPath = outputPdfPath;
        }
    }

    qDebug() << "Saving receipt as PDF to:" << outputPath;

    // Extract dimension parameters from URL if present
    QUrl url(sourcePdfPath);
    QUrlQuery query(url.query());
    bool hasDimensions = false;
    int paperWidthMM = 0;
    int paperHeightPt = 0;

    if (query.hasQueryItem(QStringLiteral("paperWidth")) && query.hasQueryItem(QStringLiteral("paperHeight"))) {
        paperWidthMM = query.queryItemValue(QStringLiteral("paperWidth")).toInt();
        paperHeightPt = query.queryItemValue(QStringLiteral("paperHeight")).toInt();
        hasDimensions = (paperWidthMM > 0 && paperHeightPt > 0);
    }

    // Configure printer for PDF output
    printer.setOutputFormat(QPrinter::PdfFormat);
    printer.setOutputFileName(outputPath);
    printer.setDocName(fileInfo.fileName());

    // Apply dimensions from PDF metadata if available
    if (hasDimensions) {
        qDebug() << "Using embedded PDF dimensions: Width=" << paperWidthMM
                << "mm, Height=" << paperHeightPt << "pt";

        // Convert height from points to mm (1pt ≈ 0.35mm)
        qreal paperHeightMM = paperHeightPt * 0.35;

        // Add extra margin to ensure content isn't cut off (20% extra)
        paperHeightMM *= 1.2;

        // Create a custom page size with the exact dimensions
        QPageSize customPageSize(QSizeF(paperWidthMM, paperHeightMM),
                               QPageSize::Millimeter,
                               QStringLiteral("Custom_%1x%2mm").arg(paperWidthMM).arg(paperHeightMM));

        printer.setPageSize(customPageSize);
        printer.setPageOrientation(QPageLayout::Portrait);

        // Force no margins
        printer.setFullPage(true);

        // Set page margins to zero
        QMarginsF margins(0, 0, 0, 0);
        QPageLayout layout = printer.pageLayout();
        layout.setPageSize(customPageSize);
        layout.setMargins(margins);
        printer.setPageLayout(layout);
    }

    // Load the PDF document
    std::unique_ptr<Poppler::Document> document(Poppler::Document::load(filePath));
    if (!document) {
        qWarning() << "Failed to load PDF document";
        return false;
    }

    if (document->isLocked()) {
        qWarning() << "PDF document is locked/encrypted";
        return false;
    }

    // Get document information
    int numPages = document->numPages();
    qDebug() << "PDF document loaded successfully. Pages:" << numPages;

    if (numPages == 0) {
        qWarning() << "PDF document has no pages";
        return false;
    }

    // Set document rendering hints for best quality
    document->setRenderHint(Poppler::Document::Antialiasing, true);
    document->setRenderHint(Poppler::Document::TextAntialiasing, true);
    document->setRenderHint(Poppler::Document::TextHinting, true);
    document->setRenderHint(Poppler::Document::ThinLineSolid, true);

    // If we have embedded dimensions, use simplified rendering for PDF
    bool result;
    if (hasDimensions) {
        result = renderDocumentWithOriginalSize(document, &printer);
    } else {
        // Fallback to standard rendering
        result = renderDocument(document, &printer);
    }

    // Reset printer output format back to standard printing
    printer.setOutputFormat(QPrinter::NativeFormat);

    if (result) {
        qDebug() << "Successfully saved PDF to:" << outputPath;
    } else {
        qWarning() << "Failed to save PDF to:" << outputPath;
    }

    return result;
}

bool PrinterHelper::printThermalReceipt(const QString &pdfPath)
{
    QString filePath = normalizeFilePath(pdfPath);
    QFileInfo fileInfo(filePath);

    if (!fileInfo.exists()) {
        qWarning() << "PDF file does not exist:" << filePath;
        return false;
    }

    // Extract dimension parameters from URL if present
    QUrl url(pdfPath);
    QUrlQuery query(url.query());
    bool hasDimensions = false;
    int paperWidthMM = 0;
    int paperHeightPt = 0;

    if (query.hasQueryItem(QStringLiteral("paperWidth")) && query.hasQueryItem(QStringLiteral("paperHeight"))) {
        paperWidthMM = query.queryItemValue(QStringLiteral("paperWidth")).toInt();
        paperHeightPt = query.queryItemValue(QStringLiteral("paperHeight")).toInt();
        hasDimensions = (paperWidthMM > 0 && paperHeightPt > 0);
    }

    // Set document name from file name
    printer.setDocName(fileInfo.fileName());

    // Apply dimensions from PDF metadata if available
    if (hasDimensions) {
        qDebug() << "Using embedded PDF dimensions: Width=" << paperWidthMM
                 << "mm, Height=" << paperHeightPt << "pt";

        // Convert height from points to mm (1pt ≈ 0.35mm)
        qreal paperHeightMM = paperHeightPt * 0.35;

        // Create a custom page size with the exact dimensions
        QPageSize customPageSize(QSizeF(paperWidthMM, paperHeightMM),
                                QPageSize::Millimeter,
                                QStringLiteral("Custom_%1x%2mm").arg(paperWidthMM).arg(paperHeightMM));

        printer.setPageSize(customPageSize);
        printer.setPageOrientation(QPageLayout::Portrait);
    }

    // Load the PDF document
    std::unique_ptr<Poppler::Document> document(Poppler::Document::load(filePath));
    if (!document) {
        qWarning() << "Failed to load PDF document";
        return false;
    }

    if (document->isLocked()) {
        qWarning() << "PDF document is locked/encrypted";
        return false;
    }

    // Get document information
    int numPages = document->numPages();
    qDebug() << "PDF document loaded successfully. Pages:" << numPages;

    if (numPages == 0) {
        qWarning() << "PDF document has no pages";
        return false;
    }

    // Set document rendering hints for best quality
    document->setRenderHint(Poppler::Document::Antialiasing, true);
    document->setRenderHint(Poppler::Document::TextAntialiasing, true);
    document->setRenderHint(Poppler::Document::TextHinting, true);
    document->setRenderHint(Poppler::Document::ThinLineSolid, true);

    // Show print dialog
    QPrintDialog dialog(&printer);
    if (dialog.exec() != QDialog::Accepted) {
        return false;
    }

    // Check if a printer was selected
    if (printer.printerName().isEmpty()) {
        qWarning() << "No printer selected";
        return false;
    }

    qDebug() << "Printing to printer:" << printer.printerName();

    // If we have embedded dimensions, use simplified rendering
    if (hasDimensions) {
        return renderDocumentWithOriginalSize(document, &printer);
    }

    // Fallback to standard rendering
    return renderDocument(document, &printer);
}
bool PrinterHelper::printReceiptWithConfig(const QString &pdfUrl, const QString &configName)
{
    // Load configuration from storage
    QVariantMap config = loadPrinterConfig(configName);

    // Get file path from URL
    QString filePath = normalizeFilePath(pdfUrl);
    QFileInfo fileInfo(filePath);

    if (!fileInfo.exists()) {
        qWarning() << "PDF file does not exist:" << filePath;
        return false;
    }

    // Get settings from config
    bool directPrint = config.value(QStringLiteral("directPrint"), false).toBool();
    bool grayscale = config.value(QStringLiteral("grayscale"), true).toBool();
    int copies = config.value(QStringLiteral("copies"), 1).toInt();
    QString printerName = config.value(QStringLiteral("printerName"),QStringLiteral("")).toString();
    qreal zoomFactor = config.value(QStringLiteral("zoom"), 1.0).toDouble();
    this->xOffset = config.value(QStringLiteral("xOffset"), 0).toInt();
    this->yOffset = config.value(QStringLiteral("yOffset"), 0).toInt();

    qDebug() << "Printing receipt with config:" << configName;
    qDebug() << "  Direct print:" << directPrint;
    qDebug() << "  Grayscale:" << grayscale;
    qDebug() << "  Copies:" << copies;
    qDebug() << "  Printer name:" << (printerName.isEmpty() ? QStringLiteral("(default)") : printerName);
    qDebug() << "  Zoom:" << zoomFactor;
    qDebug() << "  Offsets:" << "x=" << xOffset << "y=" << yOffset;

    // Configure the printer with our loaded settings
    printer.setDocName(fileInfo.fileName());
    printer.setColorMode(grayscale ? QPrinter::GrayScale : QPrinter::Color);
    printer.setCopyCount(copies);
    setZoom(zoomFactor);

    // Set specific printer if provided
    if (!printerName.isEmpty()) {
        printer.setPrinterName(printerName);
    }

    // Extract dimension parameters from URL if present
    QUrl url(pdfUrl);
    QUrlQuery query(url.query());
    bool hasDimensions = false;
    int paperWidthMM = 0;
    int paperHeightPt = 0;

    if (query.hasQueryItem(QStringLiteral("paperWidth")) && query.hasQueryItem(QStringLiteral("paperHeight"))) {
        paperWidthMM = query.queryItemValue(QStringLiteral("paperWidth")).toInt();
        paperHeightPt = query.queryItemValue(QStringLiteral("paperHeight")).toInt();
        hasDimensions = (paperWidthMM > 0 && paperHeightPt > 0);
    }

    // Apply dimensions from PDF metadata if available
    if (hasDimensions) {
        qDebug() << "Using embedded PDF dimensions: Width=" << paperWidthMM
                 << "mm, Height=" << paperHeightPt << "pt";

        // Convert height from points to mm (1pt ≈ 0.35mm)
        qreal paperHeightMM = paperHeightPt * 0.35;

        // Create a custom page size with the exact dimensions
        QPageSize customPageSize(QSizeF(paperWidthMM, paperHeightMM),
                                QPageSize::Millimeter,
                                QStringLiteral("Custom_%1x%2mm").arg(paperWidthMM).arg(paperHeightMM));

        printer.setPageSize(customPageSize);
        printer.setPageOrientation(QPageLayout::Portrait);
    }

    // Load the PDF document
    std::unique_ptr<Poppler::Document> document(Poppler::Document::load(filePath));
    if (!document) {
        qWarning() << "Failed to load PDF document";
        return false;
    }

    if (document->isLocked()) {
        qWarning() << "PDF document is locked/encrypted";
        return false;
    }

    // Set document rendering hints for best quality
    document->setRenderHint(Poppler::Document::Antialiasing, true);
    document->setRenderHint(Poppler::Document::TextAntialiasing, true);
    document->setRenderHint(Poppler::Document::TextHinting, true);
    document->setRenderHint(Poppler::Document::ThinLineSolid, true);

    // Handle direct print vs. dialog based on settings
    if (directPrint) {
        qDebug() << "Performing direct print to printer:" << printer.printerName();

        // Start painting directly to printer without showing dialog
        QPainter painter;
        if (!painter.begin(&printer)) {
            qWarning() << "Failed to begin painting on printer";
            return false;
        }

        // Render the document directly
        if (hasDimensions) {
            // Use page dimensions from URL
            renderDocumentToPainter(document.get(), &painter, &printer);
        } else {
            // Fall back to standard rendering
            for (int i = 0; i < document->numPages(); ++i) {
                if (i > 0) {
                    printer.newPage();
                }

                // Get the page
                std::unique_ptr<Poppler::Page> page(document->page(i));
                if (!page) continue;

                // Render at high quality
                QImage image = page->renderToImage(300.0 * zoomFactor, 300.0 * zoomFactor);
                if (image.isNull()) continue;

                // Calculate scale to fit printer page
                QRect printerRect = printer.pageLayout().paintRectPixels(printer.resolution());
                double scale = (double)printerRect.width() / image.width();
                int targetWidth = printerRect.width();
                int targetHeight = image.height() * scale;

                // Center on page with offsets
                int xPos = (printerRect.width() - targetWidth) / 2 + xOffset;
                int yPos = (printerRect.height() - targetHeight) / 2 + yOffset;

                // Ensure valid positions
                xPos = qMax(0, xPos);
                yPos = qMax(0, yPos);

                // Draw with high quality
                QRect targetRect(xPos, yPos, targetWidth, targetHeight);
                painter.setRenderHint(QPainter::SmoothPixmapTransform, true);
                painter.setRenderHint(QPainter::Antialiasing, true);
                painter.drawImage(targetRect, image);
            }
        }

        // End painting
        bool success = painter.end();
        if (success) {
            qDebug() << "Direct printing completed successfully";
        } else {
            qWarning() << "Direct printing ended with error";
        }
        return success;
    } else {
        // Show print dialog
        QPrintDialog dialog(&printer);
        if (dialog.exec() != QDialog::Accepted) {
            return false;
        }

        // Use regular rendering after dialog
        if (hasDimensions) {
            return renderDocumentWithOriginalSize(document, &printer);
        } else {
            return renderDocument(document, &printer);
        }
    }
}

// Helper method to render document to an existing painter
bool PrinterHelper::renderDocumentToPainter(Poppler::Document* document, QPainter* painter, QPrinter* printer)
{
    if (!document || !painter || !printer) {
        return false;
    }

    // Get printer information
    QRect printerRect = printer->pageLayout().paintRectPixels(printer->resolution());

    // Render each page
    for (int i = 0; i < document->numPages(); ++i) {
        if (i > 0) {
            printer->newPage();
        }

        // Get the page
        std::unique_ptr<Poppler::Page> page(document->page(i));
        if (!page) continue;

        // Render at high quality
        QImage image = page->renderToImage(300.0 * zoomFactor, 300.0 * zoomFactor);
        if (image.isNull()) continue;

        // Calculate scale to fit printer page
        double scale = (double)printerRect.width() / image.width();
        int targetWidth = printerRect.width();
        int targetHeight = image.height() * scale;

        // Center on page with offsets
        int xPos = (printerRect.width() - targetWidth) / 2 + xOffset;
        int yPos = 0 + yOffset; // Align to top for thermal receipts

        // Ensure valid positions
        xPos = qMax(0, xPos);
        yPos = qMax(0, yPos);

        // Draw with high quality
        QRect targetRect(xPos, yPos, targetWidth, targetHeight);
        painter->setRenderHint(QPainter::SmoothPixmapTransform, true);
        painter->setRenderHint(QPainter::Antialiasing, true);
        painter->drawImage(targetRect, image);
    }

    return true;
}

bool PrinterHelper::printThermalReceiptWithSettings(const QString &pdfPath, const QString &configName)
{
    // Load saved printer settings
    QVariantMap printerSettings = loadPrinterConfig(configName);

    QString filePath = normalizeFilePath(pdfPath);
    QFileInfo fileInfo(filePath);

    if (!fileInfo.exists()) {
        qWarning() << "PDF file does not exist:" << filePath;
        return false;
    }

    // Apply settings loaded from configuration
    bool directPrint = printerSettings.value(QStringLiteral("directPrint"), false).toBool();
    bool grayscale = printerSettings.value(QStringLiteral("grayscale"), true).toBool();
    int copies = printerSettings.value(QStringLiteral("copies"), 1).toInt();
    QString printerName = printerSettings.value(QStringLiteral("printerName"), QStringLiteral("")).toString();
    qreal zoom = printerSettings.value(QStringLiteral("zoom"), 1.0).toDouble();
    int xOffset = printerSettings.value(QStringLiteral("xOffset"), 0).toInt();
    int yOffset = printerSettings.value(QStringLiteral("yOffset"), 0).toInt();

    qDebug() << "Printing with settings:"
             << "directPrint=" << directPrint
             << "grayscale=" << grayscale
             << "copies=" << copies
             << "printer=" << (printerName.isEmpty() ? QStringLiteral("default") : printerName)
             << "zoom=" << zoom;

    // Set printer options
    setColorMode(!grayscale); // Note: setColorMode(true) means color, not grayscale
    setCopyCount(copies);
    setZoom(zoom);

    // Set printer name if specified
    if (!printerName.isEmpty()) {
        setPrinterName(printerName);
    }

    // Store offsets for rendering
    this->xOffset = xOffset;
    this->yOffset = yOffset;

    // Extract dimension parameters from URL if present
    QUrl url(pdfPath);
    QUrlQuery query(url.query());
    bool hasDimensions = false;
    int paperWidthMM = 0;
    int paperHeightPt = 0;

    if (query.hasQueryItem(QStringLiteral("paperWidth")) && query.hasQueryItem(QStringLiteral("paperHeight"))) {
        paperWidthMM = query.queryItemValue(QStringLiteral("paperWidth")).toInt();
        paperHeightPt = query.queryItemValue(QStringLiteral("paperHeight")).toInt();
        hasDimensions = (paperWidthMM > 0 && paperHeightPt > 0);
    }

    // Set document name from file name
    printer.setDocName(fileInfo.fileName());

    // Apply dimensions from PDF metadata if available
    if (hasDimensions) {
        qDebug() << "Using embedded PDF dimensions: Width=" << paperWidthMM
                 << "mm, Height=" << paperHeightPt << "pt";

        // Convert height from points to mm (1pt ≈ 0.35mm)
        qreal paperHeightMM = paperHeightPt * 0.35;

        // Create a custom page size with the exact dimensions
        QPageSize customPageSize(QSizeF(paperWidthMM, paperHeightMM),
                                QPageSize::Millimeter,
                                QStringLiteral("Custom_%1x%2mm").arg(paperWidthMM).arg(paperHeightMM));

        printer.setPageSize(customPageSize);
        printer.setPageOrientation(QPageLayout::Portrait);
    }

    // Load the PDF document
    std::unique_ptr<Poppler::Document> document(Poppler::Document::load(filePath));
    if (!document) {
        qWarning() << "Failed to load PDF document";
        return false;
    }

    if (document->isLocked()) {
        qWarning() << "PDF document is locked/encrypted";
        return false;
    }

    // Get document information
    int numPages = document->numPages();
    qDebug() << "PDF document loaded successfully. Pages:" << numPages;

    if (numPages == 0) {
        qWarning() << "PDF document has no pages";
        return false;
    }

    // Set document rendering hints for best quality
    document->setRenderHint(Poppler::Document::Antialiasing, true);
    document->setRenderHint(Poppler::Document::TextAntialiasing, true);
    document->setRenderHint(Poppler::Document::TextHinting, true);
    document->setRenderHint(Poppler::Document::ThinLineSolid, true);

    // Check if we should print directly without showing dialog
    if (directPrint) {
        qDebug() << "Performing direct print to: " << printer.printerName();

        // If we have embedded dimensions, use simplified rendering
        if (hasDimensions) {
            return renderDocumentWithOriginalSize(document, &printer);
        } else {
            // Fallback to standard rendering
            return renderDocument(document, &printer);
        }
    } else {
        // Show print dialog
        QPrintDialog dialog(&printer);
        if (dialog.exec() != QDialog::Accepted) {
            return false;
        }

        // Check if a printer was selected
        if (printer.printerName().isEmpty()) {
            qWarning() << "No printer selected";
            return false;
        }

        qDebug() << "Printing to printer:" << printer.printerName();

        // If we have embedded dimensions, use simplified rendering
        if (hasDimensions) {
            return renderDocumentWithOriginalSize(document, &printer);
        } else {
            // Fallback to standard rendering
            return renderDocument(document, &printer);
        }
    }
}

bool PrinterHelper::renderDocumentWithOriginalSize(const std::unique_ptr<Poppler::Document>& document, QPrinter* printer)
{
    if (!document) {
        qWarning() << "Invalid document!";
        return false;
    }

    // Check if we're printing to PDF
    bool isPdfOutput = printer->outputFormat() == QPrinter::PdfFormat;

    QPainter painter;
    if (!painter.begin(printer)) {
        qWarning() << "Failed to initialize painter";
        return false;
    }

    // Variables for determining total content height for PDF output
    int totalHeight = 0;
    int currentYPos = 0;

    // Simple rendering that just scales to fit the page width
    for (int i = 0; i < document->numPages(); ++i) {
        if (i > 0 && !isPdfOutput) {
            // For physical printers, create a new page for each document page
            if (!printer->newPage()) {
                qWarning() << "Failed to create new page";
                break;
            }
            currentYPos = 0; // Reset Y position for new page
        } else if (i > 0 && isPdfOutput) {
            // For PDF output, add some vertical space between pages
            currentYPos += 10; // 10px spacing between pages
        }

        std::unique_ptr<Poppler::Page> page(document->page(i));
        if (!page) continue;

        // Get printer's dimensions
        QRect printerRect = printer->pageLayout().paintRectPixels(printer->resolution());
        if (printerRect.isEmpty()) {
            qWarning() << "Invalid printer rectangle";
            continue;
        }

        // Render at high quality with error checking
        QImage image = page->renderToImage(300, 300);
        if (image.isNull()) {
            qWarning() << "Failed to render page" << i;
            continue;
        }

        // Scale to fit paper width with bounds checking
        qreal scale = (qreal)printerRect.width() / qMax(1.0, (qreal)image.width());
        int destWidth = printerRect.width();
        int destHeight = qRound(image.height() * scale);

        // For PDF output, we need to ensure all content fits vertically
        if (isPdfOutput) {
            // Calculate the bottom position after rendering this page
            int bottomPos = currentYPos + destHeight;

            // Keep track of total height needed
            totalHeight = qMax(totalHeight, bottomPos);

            // If we're going to exceed the page height, we may need to adjust the page size
            if (bottomPos > printerRect.height() && i == document->numPages() - 1) {
                // This is the last page and it would be cut off
                // We should resize the page (this would require a restart of the rendering)
                qDebug() << "Content height (" << bottomPos << "px) exceeds page height ("
                         << printerRect.height() << "px), consider using a taller page";
            }
        }

        // Position in center horizontally, starting at current Y position
        int xPos = qMax(0, (printerRect.width() - destWidth) / 2 + xOffset);
        int yPos = qMax(0, currentYPos + yOffset);

        // Make sure the target rectangle is valid
        QRect targetRect(xPos, yPos, destWidth, destHeight);
        if (!targetRect.isValid()) {
            qWarning() << "Invalid target rectangle:" << targetRect;
            continue;
        }

        // Draw the image (without try/catch block)
        painter.save();
        painter.setRenderHint(QPainter::SmoothPixmapTransform, true);
        painter.setRenderHint(QPainter::Antialiasing, true);
        painter.drawImage(targetRect, image);
        painter.restore();

        // Update current Y position for next page
        if (isPdfOutput) {
            currentYPos += destHeight;
        }
    }

    return painter.end();
}

// Update the directPrintReceipt method to respect original dimensions
bool PrinterHelper::directPrintReceipt(const QString &pdfPath, const QString &printerName)
{
    QString filePath = normalizeFilePath(pdfPath);
    QFileInfo fileInfo(filePath);

    if (!fileInfo.exists()) {
        qWarning() << "PDF file does not exist:" << filePath;
        return false;
    }

    // Extract dimension parameters from URL if present
    QUrl url(pdfPath);
    QUrlQuery query(url.query());
    bool hasDimensions = false;
    int paperWidthMM = 0;
    int paperHeightPt = 0;

    if (query.hasQueryItem(QStringLiteral("paperWidth")) && query.hasQueryItem(QStringLiteral("paperHeight"))) {
        paperWidthMM = query.queryItemValue(QStringLiteral("paperWidth")).toInt();
        paperHeightPt = query.queryItemValue(QStringLiteral("paperHeight")).toInt();
        hasDimensions = (paperWidthMM > 0 && paperHeightPt > 0);
    }

    // Set document name from file name
    printer.setDocName(fileInfo.fileName());

    // Set specific printer if provided
    if (!printerName.isEmpty()) {
        qDebug() << "Setting printer name to:" << printerName;
        printer.setPrinterName(printerName);
    } else {
        qDebug() << "Using default printer";
    }

    // Apply dimensions from PDF metadata if available
    if (hasDimensions) {
        qDebug() << "Using embedded PDF dimensions: Width=" << paperWidthMM
                 << "mm, Height=" << paperHeightPt << "pt";

        // Convert height from points to mm (1pt ≈ 0.35mm)
        qreal paperHeightMM = paperHeightPt * 0.35;

        // Create a custom page size with the exact dimensions
        QPageSize customPageSize(QSizeF(paperWidthMM, paperHeightMM),
                                QPageSize::Millimeter,
                                QStringLiteral("Custom_%1x%2mm").arg(paperWidthMM).arg(paperHeightMM));

        printer.setPageSize(customPageSize);
        printer.setPageOrientation(QPageLayout::Portrait);
    }

    // Load the PDF document
    std::unique_ptr<Poppler::Document> document(Poppler::Document::load(filePath));
    if (!document) {
        qWarning() << "Failed to load PDF document";
        return false;
    }

    if (document->isLocked()) {
        qWarning() << "PDF document is locked/encrypted";
        return false;
    }

    // Get document information
    int numPages = document->numPages();
    qDebug() << "PDF document loaded successfully. Pages:" << numPages;

    if (numPages == 0) {
        qWarning() << "PDF document has no pages";
        return false;
    }

    // Set document rendering hints for best quality
    document->setRenderHint(Poppler::Document::Antialiasing, true);
    document->setRenderHint(Poppler::Document::TextAntialiasing, true);
    document->setRenderHint(Poppler::Document::TextHinting, true);
    document->setRenderHint(Poppler::Document::ThinLineSolid, true);

    // If we have embedded dimensions, use simplified rendering
    if (hasDimensions) {
        return renderDocumentWithOriginalSize(document, &printer);
    }

    // Fallback to standard rendering
    return renderDocument(document, &printer);
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
