#include "distancemeasureplugin.h"

#include <QCoreApplication>

#include "kernel/kernel.h"
#include "kernel/kernelui.h"

#include "interface/modelinterface.h"
#include "interface/commandinterface.h"
#include "interface/uiinterface.h"

#include "dismeasurecommand.h"

DistanceMeasurePlugin::DistanceMeasurePlugin(QObject* parent)
    : QObject(parent)
		, command_(nullptr) {}

DistanceMeasurePlugin::~DistanceMeasurePlugin() {
	if (command_) {
    if (command_->parent()) {
      uninitialize();
    }

    command_->deleteLater();
  }
}

QString DistanceMeasurePlugin::name() { return QStringLiteral("DistanceMeasurePlugin"); }

QString DistanceMeasurePlugin::info() { return QStringLiteral("DistanceMeasurePlugin"); }

void DistanceMeasurePlugin::initialize() {
	if (!creative_kernel::getKernel()->globalConst()->isDistanceMeasureable()) {
    return;
  }

  command_ = new DistanceMeasureCommand(this);
	onThemeChanged(creative_kernel::currentTheme());
  onLanguageChanged(creative_kernel::currentLanguage());
  getKernelUI()->addToolCommand(command_,
    qtuser_qml::ToolCommandGroupType::LEFT_TOOLBAR_OTHER,
    qtuser_qml::ToolCommandType::DISTANCE_MEASURE);
	creative_kernel::addUIVisualTracer(this);
}

void DistanceMeasurePlugin::uninitialize() {
  getKernelUI()->removeToolCommand(command_, qtuser_qml::ToolCommandGroupType::LEFT_TOOLBAR_MAIN);
}

void DistanceMeasurePlugin::onThemeChanged(creative_kernel::ThemeCategory theme) {
  if (!command_) {
    return;
  }

  switch (theme) {
    case creative_kernel::ThemeCategory::tc_dark:
      command_->setDisabledIcon(QStringLiteral("qrc:/UI/photo/leftBar/distancemeasure_dark.svg"));
      command_->setEnabledIcon(QStringLiteral("qrc:/UI/photo/leftBar/distancemeasure_dark.svg"));
      command_->setHoveredIcon(QStringLiteral("qrc:/UI/photo/leftBar/distancemeasure_pressed.svg"));
      command_->setPressedIcon(QStringLiteral("qrc:/UI/photo/leftBar/distancemeasure_pressed.svg"));
      break;
    case creative_kernel::ThemeCategory::tc_light:
      command_->setDisabledIcon(QStringLiteral("qrc:/UI/photo/leftBar/distancemeasure_lite.svg"));
      command_->setEnabledIcon(QStringLiteral("qrc:/UI/photo/leftBar/distancemeasure_lite.svg"));
      command_->setHoveredIcon(QStringLiteral("qrc:/UI/photo/leftBar/distancemeasure_lite.svg"));
      command_->setPressedIcon(QStringLiteral("qrc:/UI/photo/leftBar/distancemeasure_pressed.svg"));
      break;
    case creative_kernel::ThemeCategory::tc_num:
      break;
    default:
      break;
  }
}

void DistanceMeasurePlugin::onLanguageChanged(creative_kernel::MultiLanguage language) {
  if (!command_) {
    return;
  }

  command_->setName(QCoreApplication::translate("info", "Distance Measure"));
}
