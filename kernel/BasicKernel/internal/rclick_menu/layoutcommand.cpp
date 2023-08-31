#include "layoutcommand.h"
#include "interface/spaceinterface.h"
#include "job/nest2djob.h"
#include "cxkernel/interface/jobsinterface.h"
#include "interface/commandinterface.h"
#include "interface/machineinterface.h"

using namespace qtuser_core;
namespace creative_kernel
{
    LayoutCommand::LayoutCommand(QObject* parent)
        :ActionCommand(parent)
    {
        m_actionname = tr("Auto arrange");
        m_actionNameWithout = "Auto arrange";

        addUIVisualTracer(this);
    }

    LayoutCommand::~LayoutCommand()
    {
    }

    void LayoutCommand::execute()
    {
        creative_kernel::Nest2DJob* job = new creative_kernel::Nest2DJob();
        QList<JobPtr> jobs;
        if (currentMachineIsBelt())
        {
            job->setNestType(qcxutil::NestPlaceType::ONELINE);
        }
        jobs.push_back(JobPtr(job));
        cxkernel::executeJobs(jobs);
    }

    bool LayoutCommand::enabled()
    {
        return creative_kernel::modelns().size() > 0;
    }

    void LayoutCommand::onThemeChanged(ThemeCategory category)
    {
    }

    void LayoutCommand::onLanguageChanged(MultiLanguage language)
    {
        m_actionname = tr("Auto arrange");
    }
}