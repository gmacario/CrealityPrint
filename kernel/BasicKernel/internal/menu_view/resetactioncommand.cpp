#include "resetactioncommand.h"

#include "interface/modelinterface.h"
#include "interface/commandinterface.h"

namespace creative_kernel
{
    ResetActionCommand::ResetActionCommand(QObject* parent)
        :ActionCommand(parent)
    {
        m_actionname = tr("Reset All Model");
        m_actionNameWithout = "Reset All Model";
        m_eParentMenu = eMenuType_View;

        addUIVisualTracer(this);
    }

    ResetActionCommand::~ResetActionCommand()
    {
    }

    void ResetActionCommand::onThemeChanged(ThemeCategory category)
    {

    }

    void ResetActionCommand::onLanguageChanged(MultiLanguage language)
    {
        m_actionname = tr("Reset All Model");
    }

    void ResetActionCommand::execute()
    {
        creative_kernel::resetAllModels();
    }
}
