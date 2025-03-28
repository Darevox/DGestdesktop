#include "documentconfigmanager.h"
#include <QDebug>

using namespace Qt::StringLiterals;

DocumentConfigManager::DocumentConfigManager(QObject *parent)
    : QObject(parent)
    , m_settings(QStringLiteral("Dervox"), QStringLiteral("DGest"))
{
    loadSettings();
}

QVariantMap DocumentConfigManager::documentConfig() const
{
    return m_config;
}

void DocumentConfigManager::saveDocumentConfig()
{
    m_settings.setValue("documentConfig", m_config);
    m_settings.sync();
    Q_EMIT documentConfigChanged();

    qDebug() << "Document configuration saved:" << m_config;
}

void DocumentConfigManager::resetToDefaults()
{
    m_config = getDefaultConfig();
    saveDocumentConfig();

    // Emit all signals to update UI
    Q_EMIT showClientInfoChanged();
    Q_EMIT showAmountInWordsChanged();
    Q_EMIT showPaymentMethodsChanged();
    Q_EMIT showTaxNumbersChanged();
    Q_EMIT showNotesChanged();
    Q_EMIT showTermsConditionsChanged();
    Q_EMIT defaultNotesChanged();
    Q_EMIT thanksMessageChanged();
    Q_EMIT defaultTermsChanged();
    Q_EMIT primaryColorChanged();
    Q_EMIT logoEnabledChanged();
    Q_EMIT footerTextChanged();
    Q_EMIT invoicePrefixChanged();
    Q_EMIT quotePrefixChanged();
}

QVariantMap DocumentConfigManager::getDefaultConfig() const
{
    QVariantMap defaultConfig;

    // Document content settings
    defaultConfig["showClientInfo"_L1] = true;
    defaultConfig["showAmountInWords"_L1] = true;
    defaultConfig["showPaymentMethods"_L1] = true;
    defaultConfig["showTaxNumbers"_L1] = true;
    defaultConfig["showNotes"_L1] = true;
    defaultConfig["showThanksMessage"_L1] = true;
    defaultConfig["showTermsConditions"_L1] = true;

    // Default texts
    defaultConfig["defaultNotes"_L1] = QStringLiteral("Thank you for your business.");
    defaultConfig["thanksMessage"_L1] = QStringLiteral("Thank you for your business.");
    defaultConfig["defaultTerms"_L1] = QStringLiteral("Payment is due within 30 days of invoice date.");

    // Appearance settings
    defaultConfig["primaryColor"_L1] = QStringLiteral("#2563eb"); // Default blue color
    defaultConfig["logoEnabled"_L1] = true;
    defaultConfig["footerText"_L1] = QStringLiteral("%teamName% • %teamPhone% • %teamEmail%");

    // Numbering
    defaultConfig["invoicePrefix"_L1] = QStringLiteral("INV-");
    defaultConfig["quotePrefix"_L1] = QStringLiteral("QUOTE-");

    return defaultConfig;
}

void DocumentConfigManager::loadSettings()
{
    // Try to load existing config
    m_config = m_settings.value("documentConfig").toMap();

    // If no config exists, initialize with defaults
    if (m_config.isEmpty()) {
        m_config = getDefaultConfig();
    }

    qDebug() << "Loaded document configuration:" << m_config;
}

// Property accessors and mutators implementations
bool DocumentConfigManager::showClientInfo() const
{
    return m_config.value("showClientInfo"_L1, true).toBool();
}

void DocumentConfigManager::setShowClientInfo(bool show)
{
    if (m_config.value("showClientInfo"_L1).toBool() != show) {
        m_config["showClientInfo"_L1] = show;
        Q_EMIT showClientInfoChanged();
        Q_EMIT documentConfigChanged();
    }
}

bool DocumentConfigManager::showAmountInWords() const
{
    return m_config.value("showAmountInWords"_L1, true).toBool();
}

void DocumentConfigManager::setShowAmountInWords(bool show)
{
    if (m_config.value("showAmountInWords"_L1).toBool() != show) {
        m_config["showAmountInWords"_L1] = show;
        Q_EMIT showAmountInWordsChanged();
        Q_EMIT documentConfigChanged();
    }
}

bool DocumentConfigManager::showPaymentMethods() const
{
    return m_config.value("showPaymentMethods"_L1, true).toBool();
}

void DocumentConfigManager::setShowPaymentMethods(bool show)
{
    if (m_config.value("showPaymentMethods"_L1).toBool() != show) {
        m_config["showPaymentMethods"_L1] = show;
        Q_EMIT showPaymentMethodsChanged();
        Q_EMIT documentConfigChanged();
    }
}

bool DocumentConfigManager::showTaxNumbers() const
{
    return m_config.value("showTaxNumbers"_L1, true).toBool();
}

void DocumentConfigManager::setShowTaxNumbers(bool show)
{
    if (m_config.value("showTaxNumbers"_L1).toBool() != show) {
        m_config["showTaxNumbers"_L1] = show;
        Q_EMIT showTaxNumbersChanged();
        Q_EMIT documentConfigChanged();
    }
}

bool DocumentConfigManager::showNotes() const
{
    return m_config.value("showNotes"_L1, true).toBool();
}

void DocumentConfigManager::setShowNotes(bool show)
{
    if (m_config.value("showNotes"_L1).toBool() != show) {
        m_config["showNotes"_L1] = show;
        Q_EMIT showNotesChanged();
        Q_EMIT documentConfigChanged();
    }
}
bool DocumentConfigManager::showThanksMessage() const
{
    return m_config.value("showThanksMessage"_L1, true).toBool();
}

void DocumentConfigManager::setShowThanksMessage(bool show)
{
    if (m_config.value("showThanksMessage"_L1).toBool() != show) {
        m_config["showThanksMessage"_L1] = show;
        Q_EMIT showThanksMessageChanged();
        Q_EMIT documentConfigChanged();
    }
}
bool DocumentConfigManager::showTermsConditions() const
{
    return m_config.value("showTermsConditions"_L1, true).toBool();
}

void DocumentConfigManager::setShowTermsConditions(bool show)
{
    if (m_config.value("showTermsConditions"_L1).toBool() != show) {
        m_config["showTermsConditions"_L1] = show;
        Q_EMIT showTermsConditionsChanged();
        Q_EMIT documentConfigChanged();
    }
}

QString DocumentConfigManager::defaultNotes() const
{
    return m_config.value("defaultNotes"_L1).toString();
}

void DocumentConfigManager::setDefaultNotes(const QString &notes)
{
    if (m_config.value("defaultNotes"_L1).toString() != notes) {
        m_config["defaultNotes"_L1] = notes;
        Q_EMIT defaultNotesChanged();
        Q_EMIT documentConfigChanged();
    }
}
QString DocumentConfigManager::thanksMessage() const
{
    return m_config.value("thanksMessage"_L1).toString();
}

void DocumentConfigManager::setThanksMessage(const QString &notes)
{
    if (m_config.value("thanksMessage"_L1).toString() != notes) {
        m_config["thanksMessage"_L1] = notes;
        Q_EMIT thanksMessageChanged();
        Q_EMIT documentConfigChanged();
    }
}

QString DocumentConfigManager::defaultTerms() const
{
    return m_config.value("defaultTerms"_L1).toString();
}

void DocumentConfigManager::setDefaultTerms(const QString &terms)
{
    if (m_config.value("defaultTerms"_L1).toString() != terms) {
        m_config["defaultTerms"_L1] = terms;
        Q_EMIT defaultTermsChanged();
        Q_EMIT documentConfigChanged();
    }
}

QString DocumentConfigManager::primaryColor() const
{
    return m_config.value("primaryColor"_L1, "#2563eb"_L1).toString();
}

void DocumentConfigManager::setPrimaryColor(const QString &color)
{
    if (m_config.value("primaryColor"_L1).toString() != color) {
        m_config["primaryColor"_L1] = color;
        Q_EMIT primaryColorChanged();
        Q_EMIT documentConfigChanged();
    }
}

bool DocumentConfigManager::logoEnabled() const
{
    return m_config.value("logoEnabled"_L1, true).toBool();
}

void DocumentConfigManager::setLogoEnabled(bool enabled)
{
    if (m_config.value("logoEnabled"_L1).toBool() != enabled) {
        m_config["logoEnabled"_L1] = enabled;
        Q_EMIT logoEnabledChanged();
        Q_EMIT documentConfigChanged();
    }
}

QString DocumentConfigManager::footerText() const
{
    return m_config.value("footerText"_L1).toString();
}

void DocumentConfigManager::setFooterText(const QString &text)
{
    if (m_config.value("footerText"_L1).toString() != text) {
        m_config["footerText"_L1] = text;
        Q_EMIT footerTextChanged();
        Q_EMIT documentConfigChanged();
    }
}

QString DocumentConfigManager::invoicePrefix() const
{
    return m_config.value("invoicePrefix"_L1, "INV-"_L1).toString();
}

void DocumentConfigManager::setInvoicePrefix(const QString &prefix)
{
    if (m_config.value("invoicePrefix"_L1).toString() != prefix) {
        m_config["invoicePrefix"_L1] = prefix;
        Q_EMIT invoicePrefixChanged();
        Q_EMIT documentConfigChanged();
    }
}

QString DocumentConfigManager::quotePrefix() const
{
    return m_config.value("quotePrefix"_L1, "QUOTE-"_L1).toString();
}

void DocumentConfigManager::setQuotePrefix(const QString &prefix)
{
    if (m_config.value("quotePrefix"_L1).toString() != prefix) {
        m_config["quotePrefix"_L1] = prefix;
        Q_EMIT quotePrefixChanged();
        Q_EMIT documentConfigChanged();
    }
}
