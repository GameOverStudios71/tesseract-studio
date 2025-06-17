document.addEventListener('DOMContentLoaded', () => {
    const controls = document.querySelectorAll('.draggable-control');
    const canvasArea = document.getElementById('canvas-area');
    let draggedItem = null;
    let elementIdCounter = 0;
    let draggedItemType = null; // To store the type of the item being dragged

    function generateUniqueId() {
        return 'canvas-el-' + elementIdCounter++;
    }

    // --- Make Canvas Elements Draggable (for reordering/moving within canvas) ---
    function makeElementDraggable(element) {
        element.setAttribute('draggable', 'true');
        element.addEventListener('dragstart', (e) => {
            e.stopPropagation();
            draggedItem = element;
            draggedItemType = element.dataset.type; // Set type for canvas elements
            e.dataTransfer.setData('text/plain', element.dataset.type);
            e.dataTransfer.setData('text/element-id', element.id);
            e.dataTransfer.effectAllowed = 'move';
            element.classList.add('is-dragging');
            // console.log('Dragging existing canvas element:', element.id, "Type:", draggedItemType);
        });

        element.addEventListener('dragend', () => {
            // e.stopPropagation();
            if (draggedItem === element) {
                element.classList.remove('is-dragging');
            }
            // draggedItem = null; // Clearing draggedItem is now primarily handled by drop events or control's dragend
            draggedItemType = null; // Reset type
            // console.log('Finished dragging existing element:', element.id);
        });
    }

    // --- Make Canvas Elements Droppable (for nesting new controls or reordering existing elements) ---
    function makeElementDroppable(element) {
        element.addEventListener('dragover', (e) => {
            e.preventDefault();
            e.stopPropagation();
            const targetType = element.dataset.type;
            let canDrop = false;

            if (!draggedItemType) return; // If no type is known, do nothing

            if (draggedItemType === 'col') {
                if (targetType === 'row') canDrop = true;
            } else if (draggedItemType === 'row') {
                // Rows generally shouldn't be dropped in cols or other rows.
                // Allow if target is a special div or the main canvas (handled by canvasArea's dragover)
                if (targetType === 'div-element' && element.classList.contains('allow-rows')) {
                    canDrop = true;
                }
            } else if (draggedItemType === 'div' || draggedItemType === 'div-element') {
                if (targetType === 'col' || targetType === 'div-element' || targetType === 'row') canDrop = true;
            }


            if (canDrop && element !== draggedItem) { // Prevent dropping onto itself
                element.classList.add('drop-target-highlight');
                e.dataTransfer.dropEffect = (draggedItem && draggedItem.id && draggedItem.id !== 'controls-area') ? 'move' : 'copy';
            } else {
                element.classList.remove('drop-target-highlight');
                e.dataTransfer.dropEffect = 'none';
            }
        });

        element.addEventListener('dragleave', (e) => {
            e.stopPropagation();
            element.classList.remove('drop-target-highlight');
        });

        element.addEventListener('drop', (e) => {
            e.preventDefault();
            e.stopPropagation();
            element.classList.remove('drop-target-highlight');

            const droppedOnItem = element;
            const newElementTypeFromControl = e.dataTransfer.getData('text/plain');
            const movedElementId = e.dataTransfer.getData('text/element-id');

            if (movedElementId && draggedItem && draggedItem.id === movedElementId && draggedItem !== droppedOnItem) {
                const draggedType = draggedItem.dataset.type;

                if (draggedType === 'col' && droppedOnItem.classList.contains('row')) {
                    const rowPlaceholder = droppedOnItem.querySelector('.col-12.border.p-2.text-muted');
                    if (rowPlaceholder && rowPlaceholder.textContent.includes('New Row')) {
                        rowPlaceholder.remove();
                    }
                    droppedOnItem.appendChild(draggedItem);
                } else if ( (draggedType === 'div' || draggedType === 'div-element' || draggedType === 'row') && (droppedOnItem.classList.contains('col') || droppedOnItem.classList.contains('div-element'))) {
                     // Allow nesting divs or rows into cols or other divs
                    droppedOnItem.appendChild(draggedItem);
                } else if (droppedOnItem.classList.contains('row') && draggedType !== 'col') {
                    droppedOnItem.appendChild(draggedItem);
                } else {
                    console.warn(`Cannot directly drop ${draggedType} into ${droppedOnItem.dataset.type || droppedOnItem.className}.`);
                    // Fallback handled by draggedItem not being cleared, or could append to parent.
                    // For now, if not valid, the drop effectively cancels for this target.
                    draggedItemType = null;
                    return; // Do not clear draggedItem, let dragend handle it if drop wasn't "successful" on a valid target
                }
            } else if (newElementTypeFromControl && !movedElementId && draggedItem && draggedItem.parentElement.id === 'controls-area') { // New control from panel
                const newElement = createNewCanvasElement(newElementTypeFromControl);

                if (newElementTypeFromControl === 'col' && droppedOnItem.classList.contains('row')) {
                    const rowPlaceholder = droppedOnItem.querySelector('.col-12.border.p-2.text-muted');
                    if (rowPlaceholder && rowPlaceholder.textContent.includes('New Row')) {
                        rowPlaceholder.remove();
                    }
                    droppedOnItem.appendChild(newElement);
                } else if ( (newElementTypeFromControl === 'div' || newElementTypeFromControl === 'div-element' || newElementTypeFromControl === 'row') && (droppedOnItem.classList.contains('col') || droppedOnItem.classList.contains('div-element'))) {
                     // Allow nesting new divs or rows into cols or other divs
                    droppedOnItem.appendChild(newElement);
                } else if (droppedOnItem.classList.contains('row') && newElementTypeFromControl !== 'col') {
                     droppedOnItem.appendChild(newElement);
                } else {
                    console.warn(`Cannot directly drop new ${newElementTypeFromControl} into ${droppedOnItem.dataset.type || droppedOnItem.className}.`);
                    draggedItemType = null;
                    return;
                }
            } else {
                console.log("Drop on element condition not met:", {movedElementId, newElementTypeFromControl, draggedItemId: draggedItem ? draggedItem.id : null});
                draggedItemType = null;
                return; // Not a valid drop scenario for this element.
            }

            draggedItem = null;
            draggedItemType = null;
        });
    }

    function createNewCanvasElement(elementType) {
        const newElement = document.createElement('div');
        newElement.id = generateUniqueId();
        newElement.classList.add('canvas-element');
        newElement.dataset.type = elementType;
        newElement.setAttribute('draggable', 'true');

        if (elementType === 'row') {
            newElement.classList.add('row', 'm-0', 'p-2');
            newElement.innerHTML = '<div class="col-12 border p-2 text-muted small">New Row (drop columns or other elements here)</div>';
        } else if (elementType === 'col') {
            newElement.classList.add('col', 'border', 'p-3', 'm-1');
            newElement.textContent = 'New Column';
        } else if (elementType === 'div') {
            newElement.classList.add('div-element', 'p-3', 'border', 'm-1');
            newElement.textContent = 'New Div';
        } else {
            newElement.classList.add(elementType);
            newElement.textContent = `Element: ${elementType}`;
        }

        const deleteButton = document.createElement('button');
        deleteButton.classList.add('btn', 'btn-danger', 'btn-sm', 'delete-element-btn');
        deleteButton.innerHTML = '&times;'; // Or an SVG icon
        deleteButton.title = 'Delete Element';

        deleteButton.addEventListener('click', (e) => {
            e.stopPropagation(); // Prevent click from triggering other listeners on the element itself
            const elementToRemove = newElement;

            const parent = elementToRemove.parentElement;
            elementToRemove.remove();
            console.log('Element deleted:', elementToRemove.id);

            if (parent && parent.id === 'canvas-area' && parent.children.length === 0) {
                const placeholder = document.createElement('p');
                placeholder.classList.add('text-muted');
                placeholder.textContent = 'Drag and drop controls here to build your layout.';
                parent.appendChild(placeholder);
            }
        });

        newElement.appendChild(deleteButton);

        makeElementDraggable(newElement);
        makeElementDroppable(newElement);
        return newElement;
    }

    // --- Draggable Controls (from left panel) ---
    controls.forEach(control => {
        control.addEventListener('dragstart', (e) => {
            draggedItem = control;
            draggedItemType = control.dataset.type; // Set type for controls from palette
            e.dataTransfer.setData('text/plain', control.dataset.type);
            e.dataTransfer.effectAllowed = 'copy';
            control.classList.add('is-dragging');
            // console.log('Drag Start from Controls:', draggedItemType);
        });

        control.addEventListener('dragend', () => {
            if (draggedItem && draggedItem.isSameNode(control)) { // Check if this was the item being dragged
                 control.classList.remove('is-dragging');
            }
            // If an item was successfully dropped, draggedItem would be nullified by the drop handler.
            // If it's not null here, the drag was cancelled or failed for the control itself.
            draggedItem = null;
            draggedItemType = null; // Reset type
        });
    });

    // --- Main Canvas Area drop zone ---
    canvasArea.addEventListener('dragover', (e) => {
        if (e.target.id === 'canvas-area') {
            e.preventDefault();
            let canDropOnCanvas = false;
            if (!draggedItemType) return;

            if (draggedItemType === 'row' || draggedItemType === 'div' || draggedItemType === 'div-element') {
                canDropOnCanvas = true;
            }
            // Columns generally shouldn't be top-level, unless we implement auto-row wrapping.
            // else if (draggedItemType === 'col') canDropOnCanvas = true;


            if (canDropOnCanvas) {
                canvasArea.classList.add('drag-over');
                e.dataTransfer.dropEffect = (draggedItem && draggedItem.id && draggedItem.id !== 'controls-area' && draggedItem.parentElement.id !== 'controls-area') ? 'move' : 'copy';
            } else {
                canvasArea.classList.remove('drag-over');
                e.dataTransfer.dropEffect = 'none';
            }
        }
    });

    canvasArea.addEventListener('dragleave', (e) => {
        if (e.target.id === 'canvas-area') {
            canvasArea.classList.remove('drag-over');
        }
    });

    canvasArea.addEventListener('drop', (e) => {
        if (e.target.id !== 'canvas-area') {
            return;
        }
        e.preventDefault();
        canvasArea.classList.remove('drag-over');

        const newElementTypeFromControl = e.dataTransfer.getData('text/plain');
        const movedElementId = e.dataTransfer.getData('text/element-id');

        if (movedElementId && draggedItem && draggedItem.id === movedElementId) {
            canvasArea.appendChild(draggedItem);
        } else if (newElementTypeFromControl && !movedElementId && draggedItem && draggedItem.parentElement.id === 'controls-area') { // New control from panel
            const placeholder = canvasArea.querySelector('p.text-muted');
            if (placeholder) {
                placeholder.remove();
            }
            const newElement = createNewCanvasElement(newElementTypeFromControl);
            canvasArea.appendChild(newElement);
        } else {
            // console.log('Canvas drop: No valid element type from control or moved ID found, or draggedItem mismatch.');
        }

        draggedItem = null;
        draggedItemType = null; // Reset type
    });

    console.log('HTML Editor script loaded and initialized.');
});
