#include "localnetplugin.h"
#include "interface/uiinterface.h"

#include <QSettings>

using namespace creative_kernel;

LocalNetPlugin::LocalNetPlugin(QObject* parent) : QObject(parent)
{
	m_PrinterList = new CusListModel(this);
	m_SearchMacList = new CusScanModel(this);
	m_GcodeFileList = new GcodeListModel(this);
	m_HistoryFileList = new HistoryListModel(this);
	m_videoList = new VideoListModel(this);

	FliterProxyModel* fliterModel = new FliterProxyModel(this);
	fliterModel->setSourceModel(m_PrinterList);

	SortProxyModel* gcodeSortModel = new SortProxyModel(this);
	gcodeSortModel->setSourceModel(m_GcodeFileList);

	registerContextObject("printerListModel", fliterModel);
	registerContextObject("searchMacListModel", m_SearchMacList);
	registerContextObject("gcodeFileListModel", gcodeSortModel);
	registerContextObject("historyFileListModel", m_HistoryFileList);
	registerContextObject("videoListModel", m_videoList);
}

LocalNetPlugin::~LocalNetPlugin()
{

}

QString LocalNetPlugin::name()
{
	return "InfoPlugin";
}

QString LocalNetPlugin::info()
{
	return "";
}

void LocalNetPlugin::initialize()
{
	m_PrinterList->initialize();
}

void LocalNetPlugin::uninitialize()
{
	m_PrinterList->uninitialize();
}

