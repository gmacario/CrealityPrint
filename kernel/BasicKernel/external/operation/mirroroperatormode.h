#pragma once

#include <map>
#include <memory>

#include "basickernelexport.h"
#include "data/modeln.h"
#include "qtuser3d/module/pickable.h"
#include "qtuser3d/module/pickableselecttracer.h"
#include "qtuser3d/scene/sceneoperatemode.h"
#include "qtuser3d/entity/mirrorentity.h"

class BASIC_KERNEL_API MirrorOperateMode : public qtuser_3d::SceneOperateMode
                                         , public qtuser_3d::SelectorTracer {
  Q_OBJECT;

public:
  explicit MirrorOperateMode(QObject* parent = nullptr);
	virtual ~MirrorOperateMode() = default;

protected:
  virtual void onAttach() override;
  virtual void onDettach() override;
  
  virtual void onWheelEvent(QWheelEvent* event) override;

  virtual void onLeftMouseButtonClick(QMouseEvent* event) override;

protected:
  virtual void onSelectionsChanged() override;
  virtual void selectChanged(qtuser_3d::Pickable* pickable) override;

private:
  std::unique_ptr<qtuser_3d::MirrorEntity> entity_;
  std::map<QPointer<qtuser_3d::Pickable>, std::function<void(void)>> pickable_callback_map_;
};
