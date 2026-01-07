import React, { useCallback, useMemo } from 'react';
import {
  ReactFlow,
  Controls,
  Background,
  MiniMap,
  useNodesState,
  useEdgesState,
  addEdge,
  Panel,
  Handle,
  Position,
} from '@xyflow/react';

// Custom Page Node component
function PageNode({ data, selected }) {
  const projectSlug = data.projectSlug || 'project';
  const pageUrl = `/p/${projectSlug}/${data.slug}`;

  return (
    <div className={`ts-page-node ${selected ? 'selected' : ''}`}>
      <Handle type="target" position={Position.Left} />
      <div className="ts-page-node-header">
        <span className="ts-page-node-icon">📄</span>
        <span className="ts-page-node-label">{data.label}</span>
        <a
          href={pageUrl}
          target="_blank"
          rel="noopener noreferrer"
          className="ts-page-node-link"
          title="Open in new tab"
          onClick={(e) => e.stopPropagation()} // Prevent node selection when clicking link
        >
          ↗
        </a>
      </div>
      <div className="ts-page-node-body">
        <span className="ts-page-node-slug">/{data.slug}</span>
      </div>
      <Handle type="source" position={Position.Right} />
    </div>
  );
}

const nodeTypes = {
  page: PageNode,
};

export default function FlowEditor({
  initialNodes = [],
  initialEdges = [],
  onNodeAdd,
  onNodeDelete,
  onNodeMove,
  onEdgeAdd,
  onEdgeDelete,
  projectSlug
}) {
  // Inject projectSlug into initial nodes data
  const nodesWithSlug = useMemo(() => {
    return initialNodes.map(node => ({
      ...node,
      data: { ...node.data, projectSlug }
    }));
  }, [initialNodes, projectSlug]);

  const [nodes, setNodes, onNodesChange] = useNodesState(nodesWithSlug);
  const [edges, setEdges, onEdgesChange] = useEdgesState(initialEdges);

  // Sync nodes when initialNodes changes (e.g. from server update)
  React.useEffect(() => {
    setNodes(initialNodes.map(node => ({
      ...node,
      data: { ...node.data, projectSlug }
    })));
  }, [initialNodes, projectSlug, setNodes]);

  // Handle new connection
  const onConnect = useCallback(
    (params) => {
      const newEdge = {
        ...params,
        id: `edge-${Date.now()}`,
        type: 'smoothstep',
        animated: true,
      };
      setEdges((eds) => addEdge(newEdge, eds));
      if (onEdgeAdd) {
        onEdgeAdd({
          id: newEdge.id,
          source: params.source,
          target: params.target,
        });
      }
    },
    [setEdges, onEdgeAdd]
  );

  // Handle node position change (drag end)
  const onNodeDragStop = useCallback(
    (event, node) => {
      if (onNodeMove) {
        onNodeMove(node.id, node.position.x, node.position.y);
      }
    },
    [onNodeMove]
  );

  // Handle node delete
  const onNodesDelete = useCallback(
    (deletedNodes) => {
      deletedNodes.forEach((node) => {
        if (onNodeDelete) {
          onNodeDelete(node.id);
        }
      });
    },
    [onNodeDelete]
  );

  // Handle edge delete
  const onEdgesDelete = useCallback(
    (deletedEdges) => {
      deletedEdges.forEach((edge) => {
        if (onEdgeDelete) {
          onEdgeDelete(edge.id);
        }
      });
    },
    [onEdgeDelete]
  );

  // Add new page node
  const addNewPage = useCallback(() => {
    const newNodeId = `node-${Date.now()}`;
    const pageName = `Page ${nodes.length + 1}`;
    const pageSlug = `page-${nodes.length + 1}`;

    const newNode = {
      id: newNodeId,
      type: 'page',
      position: { x: 100 + Math.random() * 200, y: 100 + Math.random() * 200 },
      data: { label: pageName, slug: pageSlug, projectSlug },
    };

    setNodes((nds) => [...nds, newNode]);

    if (onNodeAdd) {
      onNodeAdd({
        node_id: newNodeId,
        name: pageName,
        slug: pageSlug,
        position_x: newNode.position.x,
        position_y: newNode.position.y,
      });
    }
  }, [nodes, setNodes, onNodeAdd, projectSlug]);

  return (
    <div style={{ width: '100%', height: '100%' }}>
      <ReactFlow
        nodes={nodes}
        edges={edges}
        onNodesChange={onNodesChange}
        onEdgesChange={onEdgesChange}
        onConnect={onConnect}
        onNodeDragStop={onNodeDragStop}
        onNodesDelete={onNodesDelete}
        onEdgesDelete={onEdgesDelete}
        nodeTypes={nodeTypes}
        fitView
        proOptions={{ hideAttribution: true }}
        defaultEdgeOptions={{
          type: 'smoothstep',
          animated: true,
        }}
      >
        <Controls />
        <MiniMap
          nodeColor={() => '#3b82f6'}
          maskColor="rgba(0, 0, 0, 0.8)"
        />
        <Background variant="dots" gap={20} size={1} color="#334155" />

        <Panel position="top-left" className="ts-flow-panel">
          <div className="ts-flow-panel-header">
            <h2>🧊 Tesseract Studio</h2>
            {projectSlug && <span className="project-slug">/{projectSlug}</span>}
          </div>
          <div className="ts-flow-panel-actions">
            <button onClick={addNewPage} className="ts-btn-primary ts-btn-sm">
              <span>📄</span> Add Page
            </button>
          </div>
        </Panel>

        <Panel position="bottom-left" className="ts-flow-info">
          <span>Pages: {nodes.length}</span>
          <span>Connections: {edges.length}</span>
        </Panel>
      </ReactFlow>
    </div>
  );
}
