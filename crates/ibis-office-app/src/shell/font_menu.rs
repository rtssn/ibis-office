// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (c) ibis inc.
// Additional terms under AGPL-3.0 section 7(b): see NOTICE.
//! The "installed fonts" submenu of the font menus: every font family of the system, to pick for the text.

use crate::shell::chrome::{MenuEntry, MenuItem, Submenu};
use crate::shell::editor::SlideEditor;
use gpui_kit::{Context, Window};
use std::rc::Rc;

/// The submenu of all installed fonts (`current` checked), `None` while the list is not known yet (before the first document is drawn). `pick` is called with the family chosen.
pub(crate) fn installed_fonts_entry(current: Option<&str>, pick: impl Fn(&mut SlideEditor, &str, &mut Window, &mut Context<SlideEditor>) + 'static) -> Option<MenuEntry> {
    let families = crate::render::shape_view::installed_font_families();
    if families.is_empty() {
        return None;
    }
    let pick = Rc::new(pick);
    let items: Vec<MenuEntry> = families
        .iter()
        .map(|family| {
            MenuItem::new("font.installed", family.clone())
                .checked(current == Some(family.as_str()))
                .on({
                    let (pick, family) = (pick.clone(), family.clone());
                    move |this, window, cx| pick(this, &family, window, cx)
                })
                .into()
        })
        .collect();
    Some(Submenu::tr("_shell.installed-fonts", "text_fields", items).into())
}
