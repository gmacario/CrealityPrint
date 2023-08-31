#ifndef _LOCALNETPLUGIN_H
#define _LOCALNETPLUGIN_H

#include "cuslistmodel.h"
#include "cusscanmodel.h"
#include "fliterproxymodel.h"

#include "gcodelistmodel.h"
#include "historylistmodel.h"
#include "sortproxymodel.h"
#include "videolistmodel.h"

#include "qtusercore/module/creativeinterface.h"

class LocalNetPlugin: public QObject, public CreativeInterface
{
    Q_OBJECT
	Q_INTERFACES(CreativeInterface)
    Q_PLUGIN_METADATA(IID "creative.InfoPlugin")

public:
    LocalNetPlugin(QObject* parent = nullptr);
    virtual ~LocalNetPlugin();

    QString name() override;
    QString info() override;

    void initialize() override;
    void uninitialize() override;

protected:
    CusListModel* m_PrinterList = nullptr;
	CusScanModel* m_SearchMacList = nullptr;
    GcodeListModel* m_GcodeFileList = nullptr;
	HistoryListModel* m_HistoryFileList = nullptr;
    VideoListModel* m_videoList = nullptr;
};
#endif
