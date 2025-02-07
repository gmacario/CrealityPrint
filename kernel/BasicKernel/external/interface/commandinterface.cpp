#include "commandinterface.h"

#include "data/modeln.h"
#include "data/fdmsupportgroup.h"
#include "trimesh2/TriMesh.h"

#include "utils/modelpositioninitializer.h"
#include "job/nest2djob.h"
#include "cxkernel/interface/jobsinterface.h"

#include "mmesh/trimesh/trimeshutil.h"
#include "qcxutil/trimesh2/conv.h"

#include "operation/rotateop.h"
#include "interface/spaceinterface.h"
#include "interface/machineinterface.h"

#include "spaceinterface.h"
#include "modelinterface.h"
#include "selectorinterface.h"
#include "visualsceneinterface.h"

#include "qtuser3d/math/angles.h"
#include "kernel/sensoranalytics.h"

#include "kernel/kernel.h"
#include "kernel/kernelui.h"
#include "kernel/commandcenter.h"
#include "kernel/translator.h"

namespace creative_kernel
{
    int cmdSaveAs(const QString& fileName)
    {
        std::vector<trimesh::TriMesh*> meshs;
        QList<ModelN*> models = selectionms();
        size_t size = models.size();

        if (size > 0)
        {
            for (size_t i = 0; i < models.size(); i++)
            {
                bool isfanzhuan = models.at(i)->isFanZhuan();
                QMatrix4x4 matrix = models.at(i)->globalMatrix();
                trimesh::TriMesh* meshTemp = models.at(i)->mesh();
                trimesh::TriMesh* newMesh = new trimesh::TriMesh();
                *newMesh = *meshTemp;

                trimesh::fxform xf = qcxutil::qMatrix2Xform(matrix);
                int _size = meshTemp->vertices.size();
                for (int n = 0; n < _size; ++n)
                {
                    trimesh::vec3 v = meshTemp->vertices.at(n);
                    newMesh->vertices.at(n) = xf * v;
                }
                if (isfanzhuan)
                {
                    _size = newMesh->faces.size();
                    for (int n = 0; n < _size; ++n)
                    {
                        newMesh->faces.at(n)[1] = meshTemp->faces.at(n)[2];
                        newMesh->faces.at(n)[2] = meshTemp->faces.at(n)[1];
                    }
                }
                meshs.push_back(newMesh);
            }

            trimesh::TriMesh* newmodel = new trimesh::TriMesh();
            mmesh::mergeTriMesh(newmodel, meshs);

            char buff[128];
            QByteArray qbyteTemp = fileName.toLocal8Bit();
            strcpy(buff, qbyteTemp.data());

            newmodel->write(buff);
            newmodel->clear();
        }

        qDeleteAll(meshs);
        return size;
    }

    void saveStl(const QString& fileName, ModelN* model)
    {
        std::vector<trimesh::TriMesh*> meshs;
        //QList<ModelN*> models = selectionms();
        //size_t size = models.size();

        //if (size > 0)
        {
            //for (size_t i = 0; i < models.size(); i++)
            {
                bool isfanzhuan = model->isFanZhuan();
                QMatrix4x4 matrix = model->globalMatrix();
                trimesh::TriMesh* meshTemp = model->mesh();
                trimesh::TriMesh* newMesh = new trimesh::TriMesh();
                *newMesh = *meshTemp;

                trimesh::fxform xf = qcxutil::qMatrix2Xform(matrix);
                int size = meshTemp->vertices.size();
                for (int n = 0; n < size; ++n)
                {
                    trimesh::vec3 v = meshTemp->vertices.at(n);
                    newMesh->vertices.at(n) = xf * v;
                }
                if (isfanzhuan)
                {
                    size = newMesh->faces.size();
                    for (int n = 0; n < size; ++n)
                    {
                        newMesh->faces.at(n)[1] = meshTemp->faces.at(n)[2];
                        newMesh->faces.at(n)[2] = meshTemp->faces.at(n)[1];
                    }
                }
                meshs.push_back(newMesh);
            }

            trimesh::TriMesh* newmodel = new trimesh::TriMesh();
            mmesh::mergeTriMesh(newmodel, meshs);

            char buff[128];
            QByteArray qbyteTemp = fileName.toLocal8Bit();
            strcpy(buff, qbyteTemp.data());

            newmodel->write(buff);
            newmodel->clear();
        }

        qDeleteAll(meshs);
    }

    void cmdSaveSelectStl(const QString& filePath, QList<QString>& saveNames)
    {
        QList<ModelN*> models = selectionms();
        size_t size = models.size();
        saveNames.clear();
        if (size > 0)
        {
            for (size_t i = 0; i < models.size(); i++)
            {
                QString name = models[i]->objectName();
                QString fullName = name.section(".", 0, 0) + ".stl";
                saveNames.append(fullName);
                saveStl(filePath + "/" + fullName, models[i]);
            }
        }
    }

    int cmdClone(int numb)
    {
        const QList<ModelN*>& selections = selectionms();
        if (numb <= 0 || numb > 50 || selections.size() == 0)
        {
            qDebug() << "clone invalid num.";
            return -1;
        }
        return doClone(selections, numb);
    }

    int cmdClone(QList<creative_kernel::ModelN*> copyModels)
    {
        const QList<ModelN*>& selections = copyModels;
        if (selections.size() == 0)
        {
            qDebug() << "clone invalid num.";
            return -1;
        }
        return doClone(selections);
    }

    int doClone(const QList<creative_kernel::ModelN*>& selections, const int& num)
    {
        bool isBelt = currentMachineIsBelt();
        int nameIndex = 0;
        QString sname;
        for (size_t i = 0; i < selections.size(); i++)
        {
            ModelN* m = selections.at(i);
            QString objectName = m->objectName();
            objectName.chop(4);
            for (int j = 0; j < num; ++j)
            {
                creative_kernel::ModelN* model = new creative_kernel::ModelN();

                model->setData(m->data());
                nameIndex = j;
                QString name = QString("%1-%2").arg(objectName).arg(nameIndex) + ".stl";
                //---                
                QList<ModelN*> models = modelns();
                for (int k = 0; k < models.size(); ++k)
                {
                    sname = models[k]->objectName();
                    if (name == sname)
                    {
                        nameIndex++;
                        name = QString("%1-%2").arg(objectName).arg(nameIndex) + ".stl";
                        k = -1;
                    }
                }
                //---
                model->setObjectName(name);
                if (!isBelt)
                {
                    model->setLocalPosition(m->localPosition(), true);
                    model->setLocalScale(m->localScale(), true);
                    model->setLocalQuaternion(m->localQuaternion(), true);
                }
                if (m->hasFDMSupport())
                {
                    FDMSupportGroup* fdmSup = model->fdmSupport();
                    fdmSup->buildFDMSup(m->fdmSupport()->FDMSupports());
                    model->setFDMSup(fdmSup);
                }
                if (isBelt)
                {
                    ModelPositionInitializer::layoutBelt(model, nullptr);
                    bottomModel(model);
                }
                else
                {
                    ModelPositionInitializer::nestLayout(model);
                }
                //model->needDetectError();
                addModel(model, true);
                model->updateMatrix();
            }
        }

        requestVisUpdate(true);
        checkModelRange();
        checkBedRange();
        return selections.size();
    }

    void sensorAnlyticsTrace(const QString& eventType, const QString& eventAction)
    {
        getKernel()->sensorAnalytics()->trace(eventType, eventAction);
    }

    void openUserCourseLocation()
    {
        getKernel()->commandCenter()->openUserCourseLocation();
    }

    void openLogLocation()
    {
        getKernel()->commandCenter()->openLogLocation();
    }

    void openModelLocation()
    {
        getKernel()->commandCenter()->openModelLocation();
    }

    void openUserFeedbackWebsite()
    {
        getKernel()->commandCenter()->openUserFeedbackWebsite();
    }

    void openCalibrationTutorialWebsite()
    {
        getKernel()->commandCenter()->openCalibrationTutorialWebsite();
    }

    void openFileLocation(const QString& file)
    {
        getKernel()->commandCenter()->openFileLocation(file);
    }

    void openUrl(const QString& web)
    {
        getKernel()->commandCenter()->openUrl(web);
    }

    void addUIVisualTracer(UIVisualTracer* tracer)
    {
        getKernelUI()->translator()->addUIVisualTracer(tracer);
    }

    void removeUIVisualTracer(UIVisualTracer* tracer)
    {
        getKernelUI()->translator()->removeUIVisualTracer(tracer);
    }

    void changeTheme(ThemeCategory theme)
    {
        getKernelUI()->translator()->changeTheme(theme);
    }

    void changeLanguage(MultiLanguage language)
    {
        getKernelUI()->translator()->changeLanguage(language);
    }

    MultiLanguage currentLanguage()
    {
        return getKernelUI()->translator()->currentLanguage();
    }

    ThemeCategory currentTheme()
    {
        return getKernelUI()->translator()->currentTheme();
    }

    QString generateSceneName()
    {
        return getKernel()->commandCenter()->generateSceneName();
    }

    void setKernelPhase(KernelPhaseType phase)
    {
        return getKernel()->setKernelPhase(phase);
    }
}
