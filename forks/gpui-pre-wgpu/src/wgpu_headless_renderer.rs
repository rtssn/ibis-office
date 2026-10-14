// Added by ibis inc. for ibisOffice (2026-10-14): not in the upstream gpui-pre-wgpu.
//! A renderer drawing a scene into an image without a window or a display (the export of ibisOffice).

use crate::{WgpuContext, WgpuRenderer};
use gpui::{DevicePixels, PlatformAtlas, Scene, Size};
use image::RgbaImage;
use std::sync::Arc;

pub struct WgpuHeadlessRenderer {
    renderer: WgpuRenderer,
    _context: WgpuContext,
}

impl WgpuHeadlessRenderer {
    /// Picks a GPU (a software one too) without any window.
    pub fn new() -> anyhow::Result<Self> {
        let instance = wgpu::Instance::new(wgpu::InstanceDescriptor {
            backends: wgpu::Backends::VULKAN | wgpu::Backends::GL,
            flags: wgpu::InstanceFlags::default(),
            backend_options: wgpu::BackendOptions::default(),
            memory_budget_thresholds: wgpu::MemoryBudgetThresholds::default(),
            display: None,
        });
        let context = WgpuContext::new_headless(instance)?;
        let renderer = WgpuRenderer::new_headless(
            &context,
            Size {
                width: DevicePixels(1),
                height: DevicePixels(1),
            },
        )?;
        Ok(Self {
            renderer,
            _context: context,
        })
    }
}

impl gpui::PlatformHeadlessRenderer for WgpuHeadlessRenderer {
    fn render_scene_to_image(
        &mut self,
        scene: &Scene,
        size: Size<DevicePixels>,
    ) -> anyhow::Result<RgbaImage> {
        self.renderer.update_drawable_size(size);
        self.renderer
            .render_offscreen(scene, true)?
            .ok_or_else(|| anyhow::anyhow!("no pixels were read"))
    }

    fn render_scene(&mut self, scene: &Scene, size: Size<DevicePixels>) -> anyhow::Result<()> {
        self.renderer.update_drawable_size(size);
        self.renderer.render_offscreen(scene, false)?;
        Ok(())
    }

    fn sprite_atlas(&self) -> Arc<dyn PlatformAtlas> {
        self.renderer.sprite_atlas().clone()
    }
}
