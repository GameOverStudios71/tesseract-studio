import React from 'react';
import { createRoot } from 'react-dom/client';
import ContentEditor from '../react/ContentEditor.jsx';

const ContentEditorHook = {
    mounted() {
        this.renderEditor();
    },

    updated() {
        this.renderEditor();
    },

    renderEditor() {
        const isEditable = this.el.dataset.editable === 'true';
        // Only parse content if we haven't mounted yet, or maybe never re-parse to avoid overwriting unsaved changes?
        // Actually, for isEditable toggling, we just want to update that prop.
        // But React root.render updates existing instance. prop changes work.

        // We need initial content only on first mount strictly.
        // But if we want to support external updates? For now let's assume content is managed by editor internally
        // and we only update isEditable.

        const initialContent = this.el.dataset.content ? JSON.parse(this.el.dataset.content) : null;

        if (!this.root) {
            this.root = createRoot(this.el);
        }

        this.root.render(
            React.createElement(ContentEditor, {
                initialContent: initialContent, // Tiptap usually ignores content prop updates unless we force it
                isEditable: isEditable,
                onSave: (content) => {
                    this.pushEvent('save_content', { content });
                }
            })
        );
    },

    destroyed() {
        if (this.root) {
            this.root.unmount();
        }
    }
};

export default ContentEditorHook;
