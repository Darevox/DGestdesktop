#ifndef DOCUMENTCONFIGMANAGER_H
#define DOCUMENTCONFIGMANAGER_H

#include <QObject>
#include <QSettings>
#include <QVariantMap>
#include <QString>

class DocumentConfigManager : public QObject
{
    Q_OBJECT

    // Configuration properties exposed to QML
    Q_PROPERTY(QVariantMap documentConfig READ documentConfig NOTIFY documentConfigChanged)
    Q_PROPERTY(bool showClientInfo READ showClientInfo WRITE setShowClientInfo NOTIFY showClientInfoChanged)
    Q_PROPERTY(bool showAmountInWords READ showAmountInWords WRITE setShowAmountInWords NOTIFY showAmountInWordsChanged)
    Q_PROPERTY(bool showPaymentMethods READ showPaymentMethods WRITE setShowPaymentMethods NOTIFY showPaymentMethodsChanged)
    Q_PROPERTY(bool showTaxNumbers READ showTaxNumbers WRITE setShowTaxNumbers NOTIFY showTaxNumbersChanged)
    Q_PROPERTY(bool showNotes READ showNotes WRITE setShowNotes NOTIFY showNotesChanged)
    Q_PROPERTY(bool showThanksMessage READ showThanksMessage WRITE setShowThanksMessage NOTIFY showThanksMessageChanged)
    Q_PROPERTY(bool showTermsConditions READ showTermsConditions WRITE setShowTermsConditions NOTIFY showTermsConditionsChanged)
    Q_PROPERTY(QString defaultNotes READ defaultNotes WRITE setDefaultNotes NOTIFY defaultNotesChanged)
    Q_PROPERTY(QString thanksMessage READ thanksMessage WRITE setThanksMessage NOTIFY thanksMessageChanged)
    Q_PROPERTY(QString defaultTerms READ defaultTerms WRITE setDefaultTerms NOTIFY defaultTermsChanged)
    Q_PROPERTY(QString primaryColor READ primaryColor WRITE setPrimaryColor NOTIFY primaryColorChanged)
    Q_PROPERTY(bool logoEnabled READ logoEnabled WRITE setLogoEnabled NOTIFY logoEnabledChanged)
    Q_PROPERTY(QString footerText READ footerText WRITE setFooterText NOTIFY footerTextChanged)
    Q_PROPERTY(QString invoicePrefix READ invoicePrefix WRITE setInvoicePrefix NOTIFY invoicePrefixChanged)
    Q_PROPERTY(QString quotePrefix READ quotePrefix WRITE setQuotePrefix NOTIFY quotePrefixChanged)

public:
    explicit DocumentConfigManager(QObject *parent = nullptr);

    // Core configuration methods
    Q_INVOKABLE  QVariantMap documentConfig() const;
    Q_INVOKABLE void saveDocumentConfig();
    Q_INVOKABLE void resetToDefaults();
    Q_INVOKABLE QVariantMap getDefaultConfig() const;

    // Individual property accessors and mutators
    Q_INVOKABLE bool showClientInfo() const;
    Q_INVOKABLE void setShowClientInfo(bool show);

    Q_INVOKABLE bool showAmountInWords() const;
    Q_INVOKABLE void setShowAmountInWords(bool show);

    Q_INVOKABLE bool showPaymentMethods() const;
    Q_INVOKABLE void setShowPaymentMethods(bool show);

    Q_INVOKABLE bool showTaxNumbers() const;
    Q_INVOKABLE void setShowTaxNumbers(bool show);

    Q_INVOKABLE bool showNotes() const;
    Q_INVOKABLE void setShowNotes(bool show);

    Q_INVOKABLE bool showThanksMessage() const;
    Q_INVOKABLE void setShowThanksMessage(bool show);

    Q_INVOKABLE bool showTermsConditions() const;
    Q_INVOKABLE void setShowTermsConditions(bool show);

    Q_INVOKABLE QString defaultNotes() const;
    Q_INVOKABLE void setDefaultNotes(const QString &notes);

    Q_INVOKABLE QString thanksMessage() const;
    Q_INVOKABLE void setThanksMessage(const QString &notes);

    Q_INVOKABLE QString defaultTerms() const;
    Q_INVOKABLE void setDefaultTerms(const QString &terms);

    Q_INVOKABLE QString primaryColor() const;
    Q_INVOKABLE void setPrimaryColor(const QString &color);

    Q_INVOKABLE bool logoEnabled() const;
    Q_INVOKABLE void setLogoEnabled(bool enabled);

    Q_INVOKABLE QString footerText() const;
    Q_INVOKABLE void setFooterText(const QString &text);

    Q_INVOKABLE QString invoicePrefix() const;
    Q_INVOKABLE void setInvoicePrefix(const QString &prefix);

    Q_INVOKABLE QString quotePrefix() const;
    Q_INVOKABLE void setQuotePrefix(const QString &prefix);

Q_SIGNALS:
    void documentConfigChanged();
    void showClientInfoChanged();
    void showAmountInWordsChanged();
    void showPaymentMethodsChanged();
    void showTaxNumbersChanged();
    void showNotesChanged();
    void showThanksMessageChanged();
    void showTermsConditionsChanged();
    void defaultNotesChanged();
    void thanksMessageChanged();
    void defaultTermsChanged();
    void primaryColorChanged();
    void logoEnabledChanged();
    void footerTextChanged();
    void invoicePrefixChanged();
    void quotePrefixChanged();

private:
    void loadSettings();

    QSettings m_settings;
    QVariantMap m_config;
};

#endif // DOCUMENTCONFIGMANAGER_H
