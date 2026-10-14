// Modified by ibis inc. for ibisOffice (2026-10-14): added the `headless` feature and `WgpuHeadlessRenderer`.
mod cosmic_text_system;
mod wgpu_atlas;
mod wgpu_context;
#[cfg(all(not(target_family = "wasm"), feature = "headless"))]
mod wgpu_headless_renderer;
mod wgpu_renderer;

pub use cosmic_text_system::*;
pub use wgpu;
pub use wgpu_atlas::*;
pub use wgpu_context::*;
#[cfg(all(not(target_family = "wasm"), feature = "headless"))]
pub use wgpu_headless_renderer::WgpuHeadlessRenderer;
pub use wgpu_renderer::{GpuContext, WgpuRenderer, WgpuSurfaceConfig};
