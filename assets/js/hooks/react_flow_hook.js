import React from 'react';
import { createRoot } from 'react-dom/client';
import FlowEditor from '../react/FlowEditor.jsx';

// React Flow Hook for LiveView integration
const ReactFlowHook = {
    mounted() {
        // Get initial data from data attributes
        const nodes = JSON.parse(this.el.dataset.nodes || '[]');
        const edges = JSON.parse(this.el.dataset.edges || '[]');
        const projectSlug = this.el.dataset.projectSlug || '';

        // Create React root
        this.root = createRoot(this.el);

        // Render the flow editor
        this.renderFlow(nodes, edges, projectSlug);

        // Listen for updates from LiveView
        this.handleEvent('update_flow', ({ nodes, edges }) => {
            this.renderFlow(nodes, edges, projectSlug);
        });
    },

    renderFlow(nodes, edges, projectSlug) {
        this.root.render(
            React.createElement(FlowEditor, {
                initialNodes: nodes,
                initialEdges: edges,
                projectSlug: projectSlug,
                onNodeAdd: (node) => {
                    this.pushEvent('add_page', node);
                },
                onNodeDelete: (nodeId) => {
                    this.pushEvent('request_delete_page', { node_id: nodeId });
                },
                onNodeMove: (nodeId, x, y) => {
                    this.pushEvent('move_page', { node_id: nodeId, x: x, y: y });
                },
                onEdgeAdd: (edge) => {
                    this.pushEvent('add_edge', edge);
                },
                onEdgeDelete: (edgeId) => {
                    this.pushEvent('delete_edge', { edge_id: edgeId });
                },
            })
        );
    },

    destroyed() {
        if (this.root) {
            this.root.unmount();
        }
    }
};

export default ReactFlowHook;
