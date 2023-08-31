#ifndef _US_USETTING_1589354685441_H
#define _US_USETTING_1589354685441_H
#include "basickernelexport.h"
#include "us/settingitemdef.h"
#include "us/settinggroupdef.h"
#include <QVariant>

namespace us
{
	class BASIC_KERNEL_API USetting: public QObject
	{
		Q_OBJECT
	public:
		USetting(SettingItemDef* def, QObject* parent = nullptr);
		virtual ~USetting();

		USetting* clone();

		float toFloat();
		int toInt();

		Q_INVOKABLE void setValue(const QString& str);
		Q_INVOKABLE QString str();
		Q_INVOKABLE QString key();
		Q_INVOKABLE int enumIndex();
		Q_INVOKABLE bool enabled();
		Q_INVOKABLE QString description();
		Q_INVOKABLE QString label();
		Q_INVOKABLE QVariantList enums();
		Q_INVOKABLE QString type();
		Q_INVOKABLE int level();
		Q_INVOKABLE QString unit();
		Q_INVOKABLE QString minStr();
		Q_INVOKABLE QString maxStr();

		SettingItemDef* def();
	protected:
		SettingItemDef* m_itemDef;
		QString m_str;
	};
}
#endif // _US_USETTING_1589354685441_H
