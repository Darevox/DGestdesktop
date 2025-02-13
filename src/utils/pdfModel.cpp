// pdfModel.cpp
#include "pdfModel.h"
#include "pageImageProvider.h"
#include <QDebug>
#include <QQmlEngine>
#include <QQmlContext>
using namespace Qt::StringLiterals;
static QVariantMap convertDestination(const Poppler::LinkDestination& destination)
{
    QVariantMap result;
    result["page"_L1] = destination.pageNumber() - 1;
    result["top"_L1] = destination.top();
    result["left"_L1] = destination.left();
    return result;
}

PdfModel::PdfModel(QObject* parent)
    : QObject(parent)
{}

void PdfModel::setPath(QString& pathName)
{
    if (pathName == path)
        return;

    if (pathName.isEmpty())
    {
        DEBUG << "Can't load the document, path is empty.";
        Q_EMIT error("Can't load the document, path is empty."_L1);
        return;
    }

    this->path = pathName;
    Q_EMIT pathChanged(pathName);

    // Load document
    clear();
    DEBUG << "Loading document...";
    document = std::unique_ptr<Poppler::Document>(Poppler::Document::load(path));

    if (!document || document->isLocked())
    {
        DEBUG << QStringLiteral("ERROR : Can't open the document located at %1").arg(pathName);
        Q_EMIT error(QStringLiteral("Can't open the document located at %1").arg(pathName));
        document.reset();
        return;
    }

    // Create image provider
    document->setRenderHint(Poppler::Document::Antialiasing, true);
    document->setRenderHint(Poppler::Document::TextAntialiasing, true);
    loadProvider();

    // Fill in pages data
    const int numPages = document->numPages();
    for (int i = 0; i < numPages; ++i)
    {
        std::unique_ptr<Poppler::Page> page(document->page(i));

        QVariantMap pageData;
        pageData["image"_L1] = QStringLiteral("image://%1/page/%2")
                .arg(providerName)
                .arg(i + 1);

        pageData["size"_L1] = page->pageSizeF();

        QVariantList pageLinks;
        auto links = page->links();
        for (const auto& link : links)
        {
            if (link->linkType() == Poppler::Link::Goto)
            {
                auto* gotoLink = dynamic_cast<Poppler::LinkGoto*>(link.get());
                if (gotoLink && !gotoLink->isExternal())
                {
                    QVariantMap linkMap;
                    linkMap["rect"_L1] = link->linkArea().normalized();
                    linkMap["destination"_L1] = convertDestination(gotoLink->destination());
                    pageLinks.append(linkMap);
                }
            }
        }
        pageData["links"_L1] = pageLinks;

        pages.append(pageData);
    }
    Q_EMIT pagesChanged();

    DEBUG << "Document loaded successfully";
    Q_EMIT loadedChanged();
}

void PdfModel::loadProvider()
{
    DEBUG << "Loading image provider...";
    QQmlEngine* engine = QQmlEngine::contextForObject(this)->engine();

    const QString& prefix = QString::number(quintptr(this));
    providerName = QStringLiteral("poppler%1").arg(prefix);
    engine->addImageProvider(providerName, new PageImageProvider(document.get()));

    DEBUG << "Image provider loaded successfully !"
          << qPrintable(QStringLiteral("(%1)").arg(providerName));
}

void PdfModel::clear()
{
    if (!providerName.isEmpty())
    {
        QQmlEngine* engine = QQmlEngine::contextForObject(this)->engine();
        if (engine)
            engine->removeImageProvider(providerName);
        providerName.clear();
    }

    document.reset();
    Q_EMIT loadedChanged();
    pages.clear();
    Q_EMIT pagesChanged();
}

QVariantList PdfModel::getPages() const
{
    return pages;
}

bool PdfModel::getLoaded() const
{
    return document != nullptr;
}

QVariantList PdfModel::search(int page, const QString& text, Qt::CaseSensitivity caseSensitivity)
{
    QVariantList result;
    if (!document)
    {
        qWarning() << "Poppler plugin: no document to search";
        return result;
    }

    if (page >= document->numPages() || page < 0)
    {
        qWarning() << "Poppler plugin: search page" << page << "isn't in a document";
        return result;
    }

    std::unique_ptr<Poppler::Page> p(document->page(page));
    auto searchResult = p->search(text, caseSensitivity == Qt::CaseInsensitive ?
                                      Poppler::Page::IgnoreCase :
                                      static_cast<Poppler::Page::SearchFlag>(0));

    auto pageSize = p->pageSizeF();
    for (const auto& r : searchResult)
    {
        result.append(QRectF(r.left() / pageSize.width(),
                             r.top() / pageSize.height(),
                             r.width() / pageSize.width(),
                             r.height() / pageSize.height()));
    }
    return result;
}

PdfModel::~PdfModel()
{
    clear();
}
