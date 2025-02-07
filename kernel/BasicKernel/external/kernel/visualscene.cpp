#include "visualscene.h"
#include <QtCore/QDebug>

#include "cxkernel/interface/undointerface.h"
#include "interface/eventinterface.h"
#include "interface/spaceinterface.h"
#include "interface/reuseableinterface.h"

#include "qtuser3d/framegraph/colorpicker.h"
#include "qtuser3d/framegraph/surface.h"
#include "qtuser3d/framegraph/texturerendertarget.h"

#include "interface/appsettinginterface.h"
#include "interface/renderinterface.h"
#include "interface/camerainterface.h"

#include "internal/utils/visscenehandler.h"
#include "qtuser3d/entity/rectlineentity.h"
#include "qtuser3d/geometry/basicshapecreatehelper.h"

#include "qtuser3d/scene/sceneoperatemode.h"
#include "kernel/kernel.h"
#include "data/modelspaceundo.h"
#include "qtuser3d/refactor/xentity.h"
#include "qtuser3d/refactor/xrenderpass.h"
#include "qtuser3d/refactor/xeffect.h"

namespace creative_kernel
{
	VisualScene::VisualScene(Qt3DCore::QNode* parent)
		:RenderGraph(parent)
		, m_handlerEnabled(true)
	{
		m_rootEntity = new Qt3DCore::QEntity(this);

		m_surface = new qtuser_3d::Surface(this);

		m_colorPicker = new qtuser_3d::ColorPicker();
		m_colorPicker->setParent(m_surface->getCameraViewportFrameGraphNode());
		
		m_textureRenderTarget = new qtuser_3d::TextureRenderTarget(m_rootEntity);
		m_colorPicker->setTextureRenderTarget(m_textureRenderTarget);

		connect(m_colorPicker, SIGNAL(signalUpdate()), this, SIGNAL(signalUpdate()));

		m_handler = new VisSceneHandler(this);

		m_rectLine = new qtuser_3d::RectLineEntity();
		m_rectLine->setColor(QVector4D(1.0f, 0.7530f, 0.0f, 1.0f));

		{
			m_sphereEntity = new qtuser_3d::XEntity();
			m_sphereEntity->setGeometry(qtuser_3d::BasicShapeCreateHelper::createBall(QVector3D(0, 0, 0), 1.0, 10));
			
			qtuser_3d::XRenderPass *renderPass = new qtuser_3d::XRenderPass("zproject", m_sphereEntity);
			renderPass->addFilterKeyMask("alpha", 0);

			renderPass->setPassCullFace(Qt3DRender::QCullFace::Back);
			renderPass->setPassBlend();
			renderPass->setPassStencilMask(0xFF);
			renderPass->setPassStencilOperation(Qt3DRender::QStencilOperationArguments::Keep, Qt3DRender::QStencilOperationArguments::Keep, Qt3DRender::QStencilOperationArguments::Increment);
			renderPass->setPassStencilFunction(Qt3DRender::QStencilTestArguments::Equal, 0x0, 0xFF);
			renderPass->setPassDepthTest(Qt3DRender::QDepthTest::Less);
			//m_sphereEntity->setParameter("pcolor", QVector4D(0.2275, 0.2275, 0.2353, 0.5));

			qtuser_3d::XEffect* effect = new qtuser_3d::XEffect(m_sphereEntity);
			effect->addRenderPass(renderPass);
			m_sphereEntity->setEffect(effect);

			//showPrimeTower(100.0f, 100.0f, 40.0f);
		}

		m_updateTimer = new QTimer(this);
		connect(m_updateTimer, &QTimer::timeout, this, [=]()
			{
				updateRender(true);
				m_updateTimer->stop();
			});
	}
	
	VisualScene::~VisualScene()
	{
	}

	qtuser_3d::FacePicker* VisualScene::facePicker()
	{
		return m_colorPicker;
	}

	void VisualScene::initialize()
	{
		QColor clearColor = CONFIG_GLOBAL_COLOR(visualscene_surfacecolor, visualscene_group);
		m_surface->setClearColor(clearColor);
	}

	void VisualScene::updateRender(bool updatePick)
	{
		if (updatePick)
			m_colorPicker->requestCapture();
		
		emit signalUpdate();
	}

	void VisualScene::show(Qt3DCore::QEntity* entity)
	{
		if (!entity)
			return;

		if (entity->parent() != m_rootEntity)
			entity->setParent(m_rootEntity);

		if (!entity->isEnabled())
			entity->setEnabled(true);
	}

	void VisualScene::hide(Qt3DCore::QEntity* entity)
	{
		if (entity->parent() != m_rootEntity)
			entity->setParent(m_rootEntity);

		if (entity->isEnabled())
			entity->setEnabled(false);
	}

	void VisualScene::enableHandler(bool enable)
	{
		if (enable == m_handlerEnabled)
			return;

		m_handlerEnabled = enable;
		if (m_handlerEnabled)
		{
			addKeyEventHandler(m_handler);
			addHoverEventHandler(m_handler);
			addLeftMouseEventHandler(m_handler);
		}
		else
		{
			removeKeyEventHandler(m_handler);
			removeHoverEventHandler(m_handler);
			removeLeftMouseEventHandler(m_handler);
		}
	}

	Qt3DCore::QEntity* VisualScene::sceneGraph()
	{
		return m_rootEntity;
	}

	void VisualScene::begineRender()
	{
		qInfo() << "scene begineRender";
		cacheReuseable(this);

		Qt3DRender::QCamera* qcamera = getCachedCameraEntity();
		m_surface->setCamera(qcamera);

		show(spaceEntity());

		addKeyEventHandler(m_handler);
		addHoverEventHandler(m_handler);
		addLeftMouseEventHandler(m_handler);
		m_handlerEnabled = true;

		if (m_operateMode)
		{
			m_operateMode->onAttach();
		}

		cxkernel::setUndoStack(getKernel()->modelSpaceUndo());
	}

	void VisualScene::endRender()
	{
		qInfo() << "scene endRender";
		hide(spaceEntity());

		if (m_operateMode)
		{
			m_operateMode->onDettach();
		}

		removeKeyEventHandler(m_handler);
		removeHoverEventHandler(m_handler);
		removeLeftMouseEventHandler(m_handler);

		cxkernel::setUndoStack(nullptr);
	}

	void VisualScene::updateRenderSize(const QSize& size)
	{
		if (size.width() == 0 || size.height() == 0)
			return;
		
		m_surface->updateSurfaceSize(size);
		m_colorPicker->resize(size);
		m_textureRenderTarget->resize(size);
		updateRender(true);
	}

	void VisualScene::onStartPhase()
	{
		renderDefaultRenderGraph();
	}

	void VisualScene::onStopPhase()
	{
	}

	qtuser_3d::TextureRenderTarget* VisualScene::textureRenderTarget()
	{
		return m_textureRenderTarget;
	}

	void VisualScene::showRectangleSelector(const QRect& rect)
	{
		m_rectLine->setCamera(visCamera());
		m_rectLine->setRectOfScreen(rect);
		//m_rectLine->setDepthTest(false);
		show(m_rectLine);
	}

	void VisualScene::dismissRectangleSelector()
	{
		hide(m_rectLine);
	}

	bool VisualScene::shouldMultipleSelect()
	{
		if (m_operateMode)
		{
			return m_operateMode->shouldMultipleSelect();
		}
		return false;
	}

	void VisualScene::delayCapture(int msec)
	{
		m_updateTimer->start(msec);
	}

	void VisualScene::showPrimeTower(float x, float y, float radius)
	{
		QMatrix4x4 m;
		m.translate(QVector3D(x, y, 0.0f));
		m.scale(radius);
		m_sphereEntity->setPose(m);
		show(m_sphereEntity);
		
		updateRender(false);
	}

	void VisualScene::hidePrimeTower()
	{
		hide(m_sphereEntity);
		updateRender(false);
	}

	bool VisualScene::didSelectAnyEntity(const QPoint& p)
	{
		return m_colorPicker->pick(p, nullptr);
	}

	Qt3DRender::QFrameGraphNode* VisualScene::getCameraViewportFrameGraphNode()
	{
		return m_surface->getCameraViewportFrameGraphNode();
	}
}
