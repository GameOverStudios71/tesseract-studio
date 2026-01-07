import React, { useRef, useEffect, useCallback } from 'react';
import { useEditor, EditorContent } from '@tiptap/react';
// Esbuild requires using the exported path name
import { BubbleMenu, FloatingMenu } from '@tiptap/react/menus';
import StarterKit from '@tiptap/starter-kit';
import Placeholder from '@tiptap/extension-placeholder';
import BubbleMenuExtension from '@tiptap/extension-bubble-menu';
import FloatingMenuExtension from '@tiptap/extension-floating-menu';
import TextAlign from '@tiptap/extension-text-align';
import Link from '@tiptap/extension-link';
import Image from '@tiptap/extension-image';
import Underline from '@tiptap/extension-underline';

import {
    Bold, Italic, Strikethrough, Code, Underline as UnderlineIcon,
    List, ListOrdered, CheckSquare,
    Heading1, Heading2, Heading3, Pilcrow,
    AlignLeft, AlignCenter, AlignRight, AlignJustify,
    Quote, Code2, Minus, Image as ImageIcon, Link as LinkIcon, Unlink,
    Undo, Redo, RemoveFormatting
} from 'lucide-react';

const MenuBar = ({ editor }) => {
    if (!editor) {
        return null;
    }

    const setLink = useCallback(() => {
        const previousUrl = editor.getAttributes('link').href;
        const url = window.prompt('URL', previousUrl);

        // cancelled
        if (url === null) {
            return;
        }

        // empty
        if (url === '') {
            editor.chain().focus().extendMarkRange('link').unsetLink().run();
            return;
        }

        // update
        editor.chain().focus().extendMarkRange('link').setLink({ href: url }).run();
    }, [editor]);

    const addImage = useCallback(() => {
        const url = window.prompt('Image URL');

        if (url) {
            editor.chain().focus().setImage({ src: url }).run();
        }
    }, [editor]);

    return (
        <div className="ts-editor-toolbar">
            {/* History */}
            <div className="toolbar-group">
                <button
                    onClick={() => editor.chain().focus().undo().run()}
                    disabled={!editor.can().chain().focus().undo().run()}
                    title="Undo"
                >
                    <Undo size={18} />
                </button>
                <button
                    onClick={() => editor.chain().focus().redo().run()}
                    disabled={!editor.can().chain().focus().redo().run()}
                    title="Redo"
                >
                    <Redo size={18} />
                </button>
            </div>

            <div className="toolbar-divider"></div>

            {/* Typography */}
            <div className="toolbar-group">
                <button
                    onClick={() => editor.chain().focus().toggleHeading({ level: 1 }).run()}
                    className={editor.isActive('heading', { level: 1 }) ? 'is-active' : ''}
                    title="Heading 1"
                >
                    <Heading1 size={18} />
                </button>
                <button
                    onClick={() => editor.chain().focus().toggleHeading({ level: 2 }).run()}
                    className={editor.isActive('heading', { level: 2 }) ? 'is-active' : ''}
                    title="Heading 2"
                >
                    <Heading2 size={18} />
                </button>
                <button
                    onClick={() => editor.chain().focus().toggleHeading({ level: 3 }).run()}
                    className={editor.isActive('heading', { level: 3 }) ? 'is-active' : ''}
                    title="Heading 3"
                >
                    <Heading3 size={18} />
                </button>
                <button
                    onClick={() => editor.chain().focus().setParagraph().run()}
                    className={editor.isActive('paragraph') ? 'is-active' : ''}
                    title="Paragraph"
                >
                    <Pilcrow size={18} />
                </button>
            </div>

            <div className="toolbar-divider"></div>

            {/* Marks */}
            <div className="toolbar-group">
                <button
                    onClick={() => editor.chain().focus().toggleBold().run()}
                    disabled={!editor.can().chain().focus().toggleBold().run()}
                    className={editor.isActive('bold') ? 'is-active' : ''}
                    title="Bold"
                >
                    <Bold size={18} />
                </button>
                <button
                    onClick={() => editor.chain().focus().toggleItalic().run()}
                    disabled={!editor.can().chain().focus().toggleItalic().run()}
                    className={editor.isActive('italic') ? 'is-active' : ''}
                    title="Italic"
                >
                    <Italic size={18} />
                </button>
                <button
                    onClick={() => editor.chain().focus().toggleUnderline().run()}
                    className={editor.isActive('underline') ? 'is-active' : ''}
                    title="Underline"
                >
                    <UnderlineIcon size={18} />
                </button>
                <button
                    onClick={() => editor.chain().focus().toggleStrike().run()}
                    disabled={!editor.can().chain().focus().toggleStrike().run()}
                    className={editor.isActive('strike') ? 'is-active' : ''}
                    title="Strikethrough"
                >
                    <Strikethrough size={18} />
                </button>
                <button
                    onClick={() => editor.chain().focus().toggleCode().run()}
                    disabled={!editor.can().chain().focus().toggleCode().run()}
                    className={editor.isActive('code') ? 'is-active' : ''}
                    title="Code"
                >
                    <Code size={18} />
                </button>
                <button
                    onClick={() => editor.chain().focus().unsetAllMarks().run()}
                    title="Clear Marks"
                >
                    <RemoveFormatting size={18} />
                </button>
            </div>

            <div className="toolbar-divider"></div>

            {/* Alignment */}
            <div className="toolbar-group">
                <button
                    onClick={() => editor.chain().focus().setTextAlign('left').run()}
                    className={editor.isActive({ textAlign: 'left' }) ? 'is-active' : ''}
                    title="Align Left"
                >
                    <AlignLeft size={18} />
                </button>
                <button
                    onClick={() => editor.chain().focus().setTextAlign('center').run()}
                    className={editor.isActive({ textAlign: 'center' }) ? 'is-active' : ''}
                    title="Align Center"
                >
                    <AlignCenter size={18} />
                </button>
                <button
                    onClick={() => editor.chain().focus().setTextAlign('right').run()}
                    className={editor.isActive({ textAlign: 'right' }) ? 'is-active' : ''}
                    title="Align Right"
                >
                    <AlignRight size={18} />
                </button>
                <button
                    onClick={() => editor.chain().focus().setTextAlign('justify').run()}
                    className={editor.isActive({ textAlign: 'justify' }) ? 'is-active' : ''}
                    title="Align Justify"
                >
                    <AlignJustify size={18} />
                </button>
            </div>

            <div className="toolbar-divider"></div>

            {/* Lists */}
            <div className="toolbar-group">
                <button
                    onClick={() => editor.chain().focus().toggleBulletList().run()}
                    className={editor.isActive('bulletList') ? 'is-active' : ''}
                    title="Bullet List"
                >
                    <List size={18} />
                </button>
                <button
                    onClick={() => editor.chain().focus().toggleOrderedList().run()}
                    className={editor.isActive('orderedList') ? 'is-active' : ''}
                    title="Ordered List"
                >
                    <ListOrdered size={18} />
                </button>
            </div>

            <div className="toolbar-divider"></div>

            {/* Inserts */}
            <div className="toolbar-group">
                <button
                    onClick={() => editor.chain().focus().toggleBlockquote().run()}
                    className={editor.isActive('blockquote') ? 'is-active' : ''}
                    title="Blockquote"
                >
                    <Quote size={18} />
                </button>
                <button
                    onClick={() => editor.chain().focus().toggleCodeBlock().run()}
                    className={editor.isActive('codeBlock') ? 'is-active' : ''}
                    title="Code Block"
                >
                    <Code2 size={18} />
                </button>
                <button
                    onClick={setLink}
                    className={editor.isActive('link') ? 'is-active' : ''}
                    title="Link"
                >
                    <LinkIcon size={18} />
                </button>
                <button
                    onClick={addImage}
                    title="Image"
                >
                    <ImageIcon size={18} />
                </button>
                <button
                    onClick={() => editor.chain().focus().setHorizontalRule().run()}
                    title="Horizontal Rule"
                >
                    <Minus size={18} />
                </button>
            </div>
        </div>
    );
};

const ContentEditor = ({ initialContent, isEditable, onSave }) => {
    // Debounce ref
    const saveTimeoutRef = useRef(null);

    // Memoize extensions to prevent unnecessary re-initializations or duplicate extension warnings
    const extensions = React.useMemo(() => {
        return [
            StarterKit.configure({
                // Disable extensions that we are adding explicitly with custom config or to avoid duplicates
                // StarterKit 3.x includes Link and Underline, so we disable them here to add them manually below
                link: false,
                underline: false,
            }),
            Placeholder.configure({
                placeholder: 'Start writing your amazing content...',
            }),
            BubbleMenuExtension,
            FloatingMenuExtension,
            TextAlign.configure({
                types: ['heading', 'paragraph'],
            }),
            Link.configure({
                openOnClick: false,
                autolink: true,
            }),
            Image,
            Underline,
        ];
    }, []); // Empty dependency array ensures it's only created once

    const editor = useEditor({
        extensions: extensions,
        content: initialContent || '',
        editable: isEditable,
        onUpdate: ({ editor }) => {
            // Debounce save (1 second)
            if (saveTimeoutRef.current) {
                clearTimeout(saveTimeoutRef.current);
            }

            saveTimeoutRef.current = setTimeout(() => {
                if (onSave) {
                    onSave(editor.getJSON());
                }
            }, 1000);
        },
    });

    // Update editable state if prop changes
    useEffect(() => {
        if (editor) {
            editor.setEditable(isEditable);
        }
    }, [isEditable, editor]);

    // Keyboard Shortcuts (Ctrl+S)
    useEffect(() => {
        const handleKeyDown = (e) => {
            if ((e.ctrlKey || e.metaKey) && e.key === 's') {
                e.preventDefault();
                const json = editor?.getJSON();
                if (json && onSave) {
                    // Clear pending debounce
                    if (saveTimeoutRef.current) clearTimeout(saveTimeoutRef.current);
                    onSave(json);

                    // Optional: Visual feedback could be handled by parent or toast
                    console.log('Saved via shortcut');
                }
            }
        };

        window.addEventListener('keydown', handleKeyDown);
        return () => window.removeEventListener('keydown', handleKeyDown);
    }, [editor, onSave]);

    return (
        <div className="ts-content-editor">
            {isEditable && <MenuBar editor={editor} />}

            {editor && isEditable && (
                <BubbleMenu className="ts-bubble-menu" editor={editor}>
                    <button
                        onClick={() => editor.chain().focus().toggleBold().run()}
                        className={editor.isActive('bold') ? 'is-active' : ''}
                    >
                        <Bold size={16} />
                    </button>
                    <button
                        onClick={() => editor.chain().focus().toggleItalic().run()}
                        className={editor.isActive('italic') ? 'is-active' : ''}
                    >
                        <Italic size={16} />
                    </button>
                    <button
                        onClick={() => editor.chain().focus().toggleUnderline().run()}
                        className={editor.isActive('underline') ? 'is-active' : ''}
                    >
                        <UnderlineIcon size={16} />
                    </button>
                    <button
                        onClick={() => editor.chain().focus().toggleStrike().run()}
                        className={editor.isActive('strike') ? 'is-active' : ''}
                    >
                        <Strikethrough size={16} />
                    </button>
                    <button
                        onClick={() => editor.chain().focus().toggleCode().run()}
                        className={editor.isActive('code') ? 'is-active' : ''}
                    >
                        <Code size={16} />
                    </button>
                </BubbleMenu>
            )}

            {editor && isEditable && (
                <FloatingMenu className="ts-floating-menu" editor={editor}>
                    <button
                        onClick={() => editor.chain().focus().toggleHeading({ level: 1 }).run()}
                        className={editor.isActive('heading', { level: 1 }) ? 'is-active' : ''}
                    >
                        <Heading1 size={16} />
                        Heading 1
                    </button>
                    <button
                        onClick={() => editor.chain().focus().toggleHeading({ level: 2 }).run()}
                        className={editor.isActive('heading', { level: 2 }) ? 'is-active' : ''}
                    >
                        <Heading2 size={16} />
                        Heading 2
                    </button>
                    <button
                        onClick={() => editor.chain().focus().toggleBulletList().run()}
                        className={editor.isActive('bulletList') ? 'is-active' : ''}
                    >
                        <List size={16} />
                        Bullet List
                    </button>
                </FloatingMenu>
            )}

            <EditorContent editor={editor} />
        </div>
    );
};

export default ContentEditor;
