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
function PageNode({ id, data, selected }) {
  const projectSlug = data.projectSlug || 'project';
  const isHome = data.slug === 'home' || data.slug === '/';
  // Visually represent 'home' as '/'
  const displaySlug = isHome ? '/' : `/${data.slug}`;
  const pageUrl = isHome ? `/p/${projectSlug}` : `/p/${projectSlug}/${data.slug}`;

  const handleDelete = (e) => {
    e.stopPropagation();
    if (data.onDelete) {
      data.onDelete(id, data.label);
    }
  };

  return (
    <div className={`ts-page-node ${selected ? 'selected' : ''}`}>
      <Handle type="target" position={Position.Left} />
      <div className="ts-page-node-header">
        <span className="ts-page-node-icon">
          {isHome ? <i className="fa-solid fa-house"></i> : <i className="fa-solid fa-file"></i>}
        </span>
        <span className="ts-page-node-label">{isHome ? '/' : data.label}</span>
        {isHome && <span className="text-[10px] text-cyan-400 bg-cyan-400/10 px-1 rounded ml-2">ROOT</span>}

        {!isHome && (
          <button
            className="ml-auto mr-1 w-5 h-5 rounded-full bg-red-500/10 text-red-500 hover:bg-red-500 hover:text-white flex items-center justify-center transition-all opacity-0 group-hover:opacity-100"
            onClick={handleDelete}
            title="Delete Page"
          >
            <i className="fa-solid fa-xmark text-xs"></i>
          </button>
        )}
      </div>
      <div className="ts-page-node-body">
        <a
          href={pageUrl}
          target="_blank"
          rel="noopener noreferrer"
          className="ts-page-node-slug hover:text-cyan-400 transition-colors"
          title="Open page"
          onClick={(e) => e.stopPropagation()}
        >
          {displaySlug} <i className="fa-solid fa-external-link ml-1 text-[8px]"></i>
        </a>
      </div>

      {/* Hover trigger for delete button visibility using group class on parent */}
      <style>{`
        .ts-page-node:hover .opacity-0 {
          opacity: 1;
        }
      `}</style>

      <Handle type="source" position={Position.Right} />
    </div>
  );
}

// Custom Flow Node component (reuses page node styles for acrylic look)
function FlowNode({ id, data, selected }) {
  const handleDelete = (e) => {
    e.stopPropagation();
    if (data.onDelete) {
      data.onDelete(id, data.label);
    }
  };

  return (
    <div className={`ts-page-node ${selected ? 'selected' : ''}`}>
      <Handle type="target" position={Position.Left} />
      <div className="ts-page-node-header">
        <span className="ts-page-node-icon">
          <i className="fa-solid fa-diagram-project"></i>
        </span>
        <span className="ts-page-node-label">{data.label}</span>

        <button
          className="ml-auto mr-1 w-5 h-5 rounded-full bg-red-500/10 text-red-500 hover:bg-red-500 hover:text-white flex items-center justify-center transition-all opacity-0 group-hover:opacity-100"
          onClick={handleDelete}
          title="Delete Node"
        >
          <i className="fa-solid fa-xmark text-xs"></i>
        </button>
      </div>
      <div className="ts-page-node-body">
        <div className="text-[10px] text-slate-400 px-1">Flow Logic</div>
      </div>

      <style>{`
        .ts-page-node:hover .opacity-0 {
          opacity: 1;
        }
      `}</style>
      <Handle type="source" position={Position.Right} />
    </div>
  );
}

const nodeTypes = {
  page: PageNode,
  flow: FlowNode,
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
  // Handle node delete request (opens server modal)
  const handleNodeDelete = useCallback((nodeId, nodeLabel) => {
    // Instead of window.confirm, we ask the server to show the modal
    if (onNodeDelete) {
      onNodeDelete(nodeId, nodeLabel);
      // We DO NOT remove from local state immediately anymore.
      // We wait for the server to confirm deletion and push 'update_flow'.
    }
  }, [onNodeDelete]);

  // Inject projectSlug and onDelete handler into nodes data
  // We use a function update to ensure we have the latest callbacks
  const getAugmentedNodes = useCallback((nodesToAugment) => {
    return nodesToAugment.map(node => ({
      ...node,
      data: {
        ...node.data,
        projectSlug,
        onDelete: handleNodeDelete
      }
    }));
  }, [projectSlug, handleNodeDelete]);

  const [nodes, setNodes, onNodesChange] = useNodesState(getAugmentedNodes(initialNodes));
  const [edges, setEdges, onEdgesChange] = useEdgesState(initialEdges);

  // Sync nodes when initialNodes changes from server
  React.useEffect(() => {
    // Only update if the length or content fundamentally changed to avoid loops
    // For now, simpler sync
    setNodes(getAugmentedNodes(initialNodes));
  }, [initialNodes, getAugmentedNodes, setNodes]);

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

  // Handle node delete (from Backspace key)
  const onNodesDelete = useCallback(
    (deletedNodes) => {
      deletedNodes.forEach((node) => {
        // Prevent deleting home 'root' node
        if (node.data.slug === 'home' || node.data.slug === '/') return;

        if (onNodeDelete) {
          // Calls the same handler which now triggers the server modal
          onNodeDelete(node.id, node.data.label);
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

  // Custom delete for ReactFlow hook (handles keyboard delete cancellation)
  // Actually, to prevent deletion of Home via keyboard, we should key off beforeDelete or nodesDelete
  // For this request, we prioritize the GUI button.



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
        fitViewOptions={{ maxZoom: 1 }}
        proOptions={{ hideAttribution: true }}
        defaultEdgeOptions={{
          type: 'smoothstep',
          animated: true,
          style: { stroke: '#334155', strokeWidth: 2 },
        }}
      >
        <Controls />
        <MiniMap />
        <Background variant="dots" gap={20} size={1} color="rgba(255,255,255, 0.1)" />



        <Panel position="bottom-left" className="ts-flow-info">
          <span className="flex items-center gap-2"><i className="fa-regular fa-file"></i> {nodes.length} Pages</span>
          <span className="w-px h-3 bg-white/10 mx-2"></span>
          <span className="flex items-center gap-2"><i className="fa-solid fa-diagram-project"></i> {edges.length} Connections</span>
        </Panel>
      </ReactFlow>
    </div>
  );
}
