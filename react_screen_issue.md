import React, { useState, useEffect } from 'react';
import { 
  ArrowLeft, 
  RotateCw, 
  Edit3, 
  User, 
  Eye, 
  Milestone, 
  Tag, 
  MessageSquare, 
  Paperclip, 
  MoreHorizontal, 
  CheckCircle2, 
  Circle,
  Clock,
  Send,
  ExternalLink,
  ChevronDown,
  ChevronUp,
  Smile,
  Reply
} from 'lucide-react';

/**
 * MOCK DATA
 */
const INITIAL_ISSUE = {
  id: 187,
  repo: "berlogabob/ToDo",
  title: "Fix login crash on iOS 18",
  status: "open",
  updatedAt: "2h ago",
  author: "@berlogabob",
  assignee: "@you",
  watchers: 3,
  milestone: "v1.2",
  labels: [
    { name: "bug", color: "#d73a4a" },
    { name: "high-priority", color: "#f9d0c4" },
    { name: "iOS", color: "#007aff" }
  ],
  description: `**Steps to Reproduce:**
1. Open app on a physical device running iOS 18 beta.
2. Navigate to the login screen from the welcome page.
3. Tap the "Login with GitHub" button.
4. Observe the immediate application crash.

**Expected:**
The OAuth flow should initiate smoothly without interrupting the app lifecycle.

**Actual:**
The app terminates with a \`SIGABRT\` signal in the authentication delegate.`,
  attachments: [
    { name: "crash_log.txt", type: "log" },
    { name: "screenshot_01.jpg", type: "image" }
  ],
  timeline: [
    { type: 'created', user: '@berlogabob', time: '5d ago' },
    { type: 'labeled', label: 'bug', user: '@berlogabob', time: '2h ago' },
    { type: 'assigned', user: '@you', time: '1h ago' }
  ],
  comments: [
    { id: 1, user: "@user1", text: "Confirmed on my device 👍", reactions: ["👍", "🚀"], time: "45m ago" },
    { id: 2, user: "@user2", text: "Possible fix in PR #192. It seems the context wasn't being passed correctly to the root view.", reactions: [], time: "10m ago" }
  ],
  subtasks: [
    { id: 188, title: "Update GitHub Auth SDK", status: "open" }
  ]
};

// --- Sub-components ---

const StatusBadge = ({ status, isAssignedToMe }) => {
  const isOpen = status === 'open';
  return (
    <div className={`flex items-center gap-2 px-3 py-1 rounded-full border ${isAssignedToMe ? 'border-[#FF5E00]' : 'border-[#333333]'} bg-black`}>
      {isOpen ? (
        <Circle size={12} className="fill-[#238636] text-[#238636]" />
      ) : (
        <CheckCircle2 size={12} className="text-[#6e7781]" />
      )}
      <span className={`text-sm font-medium ${isOpen ? 'text-[#F5F5F5]' : 'text-[#A0A0A5]'}`}>
        {status}
      </span>
    </div>
  );
};

const LabelChip = ({ label }) => (
  <span 
    className="px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider"
    style={{ backgroundColor: `${label.color}33`, color: label.color, border: `1px solid ${label.color}66` }}
  >
    {label.name}
  </span>
);

const TimelineItem = ({ item }) => {
  const getIcon = () => {
    switch(item.type) {
      case 'created': return <Circle size={14} className="text-gray-500" />;
      case 'labeled': return <Tag size={14} className="text-gray-500" />;
      case 'assigned': return <User size={14} className="text-[#FF5E00]" />;
      default: return <Clock size={14} className="text-gray-500" />;
    }
  };

  return (
    <div className="flex gap-4 items-start py-3 border-l border-[#333333] ml-2 pl-6 relative">
      <div className="absolute left-[-8px] top-4 bg-black p-0.5">
        {getIcon()}
      </div>
      <div className="flex flex-col">
        <p className="text-[#F5F5F5] text-sm">
          {item.type === 'created' && <span>Created by <b className="text-[#FF5E00]">{item.user}</b></span>}
          {item.type === 'labeled' && <span>Label <span className="bg-[#333333] px-1 rounded text-xs">{item.label}</span> added</span>}
          {item.type === 'assigned' && <span>Assigned to <b className="text-[#FF5E00]">{item.user}</b></span>}
        </p>
        <span className="text-[#A0A0A5] text-xs">{item.time}</span>
      </div>
    </div>
  );
};

const CommentTile = ({ comment }) => (
  <div className="bg-[#111111] border border-[#222222] rounded-xl p-4 mb-4">
    <div className="flex justify-between items-center mb-3">
      <div className="flex items-center gap-2">
        <div className="w-8 h-8 rounded-full bg-gradient-to-br from-orange-500 to-red-600 flex items-center justify-center text-xs font-bold">
          {comment.user.charAt(1).toUpperCase()}
        </div>
        <span className="text-sm font-bold text-[#F5F5F5]">{comment.user}</span>
        <span className="text-xs text-[#A0A0A5]">• {comment.time}</span>
      </div>
      <button className="text-[#A0A0A5] hover:text-[#FF5E00]">
        <MoreHorizontal size={18} />
      </button>
    </div>
    <p className="text-[#F5F5F5] text-sm leading-relaxed mb-4 whitespace-pre-wrap">
      {comment.text}
    </p>
    <div className="flex justify-between items-center">
      <div className="flex gap-2">
        {comment.reactions.map((r, i) => (
          <span key={i} className="bg-[#222222] px-2 py-1 rounded-md text-xs border border-[#333333]">{r} 1</span>
        ))}
        <button className="bg-[#222222] p-1 px-2 rounded-md border border-[#333333] text-[#A0A0A5] hover:text-[#FF5E00]">
          <Smile size={14} />
        </button>
      </div>
      <button className="flex items-center gap-1 text-xs text-[#FF5E00] font-medium px-3 py-1 hover:bg-[#FF5E0011] rounded-lg transition-colors">
        <Reply size={14} /> Reply
      </button>
    </div>
  </div>
);

// --- Main App Component ---

export default function App() {
  const [issue, setIssue] = useState(INITIAL_ISSUE);
  const [isDescExpanded, setIsDescExpanded] = useState(false);
  const [isSyncing, setIsSyncing] = useState(false);
  const [commentText, setCommentText] = useState("");

  const handleSync = () => {
    setIsSyncing(true);
    setTimeout(() => setIsSyncing(false), 1500);
  };

  return (
    <div className="min-h-screen bg-black text-[#F5F5F5] font-sans selection:bg-[#FF5E0033]">
      
      {/* Offline/Sync Banner */}
      <div className="sticky top-0 z-50">
        <div className="bg-[#FF5E00] text-black text-[10px] font-bold py-1 px-4 flex justify-between items-center uppercase tracking-widest">
          <span>Cached – Last sync 15m ago</span>
          <button onClick={handleSync} className="flex items-center gap-1">
            <RotateCw size={10} className={isSyncing ? "animate-spin" : ""} />
            Sync Now
          </button>
        </div>

        {/* AppBar */}
        <header className="bg-black/80 backdrop-blur-md border-b border-[#333333] px-6 py-4 flex items-center justify-between">
          <div className="flex items-center gap-4">
            <button className="p-2 hover:bg-[#222222] rounded-full transition-colors">
              <ArrowLeft size={20} />
            </button>
            <h1 className="text-xl font-bold tracking-tight">GitDoIt</h1>
          </div>
          <div className="flex items-center gap-2">
            <button 
              className="flex items-center gap-2 bg-[#FF5E00] text-black px-4 py-2 rounded-xl font-bold text-sm hover:scale-105 active:scale-95 transition-all"
            >
              <Edit3 size={16} /> Edit
            </button>
          </div>
        </header>
      </div>

      <main className="max-w-3xl mx-auto px-6 py-8 pb-32">
        
        {/* Header Section */}
        <section className="mb-8">
          <div className="flex items-center gap-2 text-[#A0A0A5] text-xs font-mono mb-4">
            <span>{issue.repo}</span>
            <span>/</span>
            <span className="text-[#FF5E00]">#{issue.id}</span>
          </div>

          <h2 className="text-3xl font-extrabold mb-6 leading-tight">
            {issue.title}
          </h2>

          <div className="flex flex-wrap gap-4 items-center">
            <StatusBadge status={issue.status} isAssignedToMe={issue.assignee === '@you'} />
            <div className="flex items-center gap-1 text-[#A0A0A5] text-xs">
              <Clock size={12} /> Updated {issue.updatedAt}
            </div>
            <div className="h-4 w-[1px] bg-[#333333] hidden sm:block" />
            <div className="flex items-center gap-3">
              <div className="flex items-center gap-1 text-sm">
                <User size={14} className="text-[#A0A0A5]" />
                <span className={issue.assignee === '@you' ? "text-[#FF5E00] font-bold" : "text-[#A0A0A5]"}>
                  {issue.assignee}
                </span>
              </div>
              <div className="flex items-center gap-1 text-[#A0A0A5] text-sm">
                <Eye size={14} /> {issue.watchers}
              </div>
              <div className="flex items-center gap-1 bg-[#222222] px-2 py-0.5 rounded border border-[#333333] text-[10px] text-[#A0A0A5] font-bold">
                <Milestone size={12} /> {issue.milestone}
              </div>
            </div>
          </div>

          {/* Labels */}
          <div className="flex flex-wrap gap-2 mt-6">
            {issue.labels.map((l, i) => <LabelChip key={i} label={l} />)}
          </div>
        </section>

        {/* Description Section */}
        <section className="mb-10 bg-[#0A0A0A] border border-[#222222] rounded-2xl p-6 relative">
          <h3 className="text-xs font-bold uppercase tracking-widest text-[#A0A0A5] mb-4 flex items-center gap-2">
            Description <div className="h-[1px] flex-1 bg-[#222222]" />
          </h3>
          <div className={`prose prose-invert max-w-none text-[#F5F5F5] text-sm leading-relaxed overflow-hidden transition-all duration-500 ${!isDescExpanded ? 'max-h-[180px]' : 'max-h-[2000px]'}`}>
            {issue.description.split('\n').map((line, i) => (
              <p key={i} className="mb-2">
                {line.startsWith('**') ? <b className="text-[#FF5E00]">{line.replace(/\*\*/g, '')}</b> : line}
              </p>
            ))}
          </div>
          
          <button 
            onClick={() => setIsDescExpanded(!isDescExpanded)}
            className="w-full mt-4 flex items-center justify-center gap-1 text-xs font-bold text-[#FF5E00] py-2 border-t border-[#222222] hover:bg-[#FF5E0008] transition-colors"
          >
            {isDescExpanded ? <><ChevronUp size={14} /> Show Less</> : <><ChevronDown size={14} /> Read More</>}
          </button>
        </section>

        {/* Attachments */}
        {issue.attachments.length > 0 && (
          <section className="mb-10">
            <h3 className="text-xs font-bold uppercase tracking-widest text-[#A0A0A5] mb-4">Attachments</h3>
            <div className="flex flex-wrap gap-3">
              {issue.attachments.map((file, i) => (
                <div key={i} className="flex items-center gap-3 bg-[#111111] border border-[#333333] p-3 rounded-xl hover:border-[#FF5E00] transition-colors cursor-pointer group">
                  <div className="w-10 h-10 bg-[#222222] rounded-lg flex items-center justify-center text-[#A0A0A5] group-hover:text-[#FF5E00]">
                    {file.type === 'image' ? <Paperclip size={18} /> : <ExternalLink size={18} />}
                  </div>
                  <div>
                    <div className="text-xs font-bold">{file.name}</div>
                    <div className="text-[10px] text-[#A0A0A5] uppercase">{file.type}</div>
                  </div>
                </div>
              ))}
            </div>
          </section>
        )}

        {/* Timeline */}
        <section className="mb-12">
          <h3 className="text-xs font-bold uppercase tracking-widest text-[#A0A0A5] mb-6">Activity Timeline</h3>
          <div className="pl-2">
            {issue.timeline.map((item, i) => <TimelineItem key={i} item={item} />)}
          </div>
        </section>

        {/* Comments Section */}
        <section className="mb-12">
          <div className="flex items-center justify-between mb-6">
            <h3 className="text-xs font-bold uppercase tracking-widest text-[#A0A0A5]">Comments ({issue.comments.length})</h3>
          </div>
          
          {issue.comments.map(c => <CommentTile key={c.id} comment={c} />)}

          {/* Add Comment */}
          <div className="mt-8">
            <div className="bg-[#111111] border border-[#333333] rounded-2xl p-4 focus-within:border-[#FF5E00] transition-colors">
              <textarea 
                placeholder="Leave a comment..."
                value={commentText}
                onChange={(e) => setCommentText(e.target.value)}
                className="w-full bg-transparent border-none focus:ring-0 text-sm min-h-[100px] resize-none text-[#F5F5F5] placeholder:text-[#A0A0A5]"
              />
              <div className="flex justify-between items-center mt-4 pt-4 border-t border-[#222222]">
                <div className="flex gap-2">
                  <button className="p-2 text-[#A0A0A5] hover:text-[#FF5E00]"><Smile size={18} /></button>
                  <button className="p-2 text-[#A0A0A5] hover:text-[#FF5E00]"><Paperclip size={18} /></button>
                </div>
                <button 
                  className={`flex items-center gap-2 px-6 py-2 rounded-xl font-bold text-sm transition-all ${commentText ? 'bg-[#FF5E00] text-black shadow-[0_0_20px_rgba(255,94,0,0.3)]' : 'bg-[#222222] text-[#555555] cursor-not-allowed'}`}
                  disabled={!commentText}
                >
                  <Send size={16} /> Send
                </button>
              </div>
            </div>
          </div>
        </section>

        {/* Sub-tasks */}
        <section className="mb-20">
          <div className="bg-[#111111] border border-[#222222] rounded-2xl overflow-hidden">
            <button className="w-full px-6 py-4 flex items-center justify-between text-left hover:bg-[#1a1a1a] transition-colors">
              <div className="flex items-center gap-2">
                <MessageSquare size={16} className="text-[#FF5E00]" />
                <span className="text-sm font-bold">Sub-tasks / Linked Issues</span>
                <span className="bg-[#333333] text-[10px] px-2 py-0.5 rounded-full">1</span>
              </div>
              <ChevronDown size={18} className="text-[#A0A0A5]" />
            </button>
            <div className="px-6 py-2 pb-4">
              {issue.subtasks.map(task => (
                <div key={task.id} className="flex items-center justify-between py-3 border-b border-[#222222] last:border-none">
                  <div className="flex items-center gap-3">
                    <Circle size={14} className="text-[#238636]" />
                    <span className="text-sm">#{task.id}: {task.title}</span>
                  </div>
                  <ChevronDown size={14} className="text-[#A0A0A5]" />
                </div>
              ))}
            </div>
          </div>
        </section>

      </main>

      {/* Persistent Bottom Action Bar */}
      <nav className="fixed bottom-0 left-0 right-0 bg-black/95 backdrop-blur-lg border-t border-[#333333] px-6 py-4 z-[100]">
        <div className="max-w-3xl mx-auto flex gap-3 items-center">
          <button className="flex-1 bg-[#FF5E00] text-black h-14 rounded-2xl font-black text-sm uppercase tracking-widest hover:brightness-110 active:scale-95 transition-all flex items-center justify-center gap-2">
             <CheckCircle2 size={20} /> Close Issue
          </button>
          <div className="flex gap-2">
            <button className="w-14 h-14 bg-[#222222] border border-[#333333] rounded-2xl flex items-center justify-center hover:bg-[#333333] transition-colors">
              <User size={20} className="text-[#A0A0A5]" />
            </button>
            <button className="w-14 h-14 bg-[#222222] border border-[#333333] rounded-2xl flex items-center justify-center hover:bg-[#333333] transition-colors">
              <Tag size={20} className="text-[#A0A0A5]" />
            </button>
            <button className="w-14 h-14 bg-[#222222] border border-[#333333] rounded-2xl flex items-center justify-center hover:bg-[#333333] transition-colors">
              <MoreHorizontal size={20} className="text-[#A0A0A5]" />
            </button>
          </div>
        </div>
      </nav>

      {/* Floating Status Bar Helper for Mobile */}
      <div className="fixed bottom-24 left-1/2 -translate-x-1/2 bg-[#333333]/80 backdrop-blur-md px-4 py-2 rounded-full border border-[#444444] text-[10px] font-bold uppercase tracking-tighter text-[#A0A0A5] pointer-events-none">
        Project: Q4 Sprint • <span className="text-[#FF5E00]">Triage Phase</span>
      </div>
    </div>
  );
}
