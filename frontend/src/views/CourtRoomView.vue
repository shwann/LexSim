<template>
  <div class="courtroom-view">
    <!-- 顶部：案件标题 + 状态 -->
    <div class="courtroom-header">
      <div class="case-info">
        <button class="back-btn" @click="$router.push('/')" title="返回首页">
          <svg viewBox="0 0 20 20" fill="currentColor" class="back-icon">
            <path fill-rule="evenodd" d="M9.707 16.707a1 1 0 01-1.414 0l-6-6a1 1 0 010-1.414l6-6a1 1 0 011.414 1.414L5.414 9H17a1 1 0 110 2H5.414l4.293 4.293a1 1 0 010 1.414z" clip-rule="evenodd"/>
          </svg>
        </button>
        <span class="case-icon">⚖</span>
        <div>
          <h2 class="case-title">{{ caseName || '法庭庭审模拟' }}</h2>
          <span class="case-type-badge">{{ caseTypeLabel }}</span>
        </div>
      </div>
      <div class="header-center">
        <div class="view-mode-tabs">
          <button class="mode-tab" :class="{ active: viewMode === 'speech' }" @click="viewMode = 'speech'">发言视图</button>
          <button class="mode-tab" :class="{ active: viewMode === 'full' }" @click="viewMode = 'full'">完整日志</button>
          <button class="mode-tab" :class="{ active: viewMode === 'stats' }" @click="viewMode = 'stats'">统计数据</button>
        </div>
      </div>
      <div class="status-row">
        <span class="status-dot" :class="statusClass" />
        <span class="status-text">{{ statusText }}</span>
        <span class="action-count">总动作 {{ totalActions }} &nbsp;|&nbsp; 发言 {{ speechActions.length }}</span>
      </div>
    </div>

    <!-- 庭审阶段时间轴 -->
    <div class="timeline-wrapper">
      <CourtRoomTimeline :current-round="currentRound" :total-rounds="totalRounds" />
    </div>

    <!-- ===== 发言视图双行筛选栏 ===== -->
    <div class="filter-panel" v-if="viewMode === 'speech' && actions.length > 0">
      <!-- 第一行：角色筛选 -->
      <div class="filter-row">
        <span class="filter-row-label">角色</span>
        <div class="filter-chips">
          <button class="chip" :class="{ active: activeRoleFilter === null }" @click="activeRoleFilter = null">
            全部 <em>{{ filteredByPhase.length }}</em>
          </button>
          <button
            v-for="(stat, role) in roleStatsFiltered"
            :key="role"
            class="chip"
            :class="['chip-role-' + role, { active: activeRoleFilter === role }]"
            @click="activeRoleFilter = activeRoleFilter === role ? null : role"
          >
            <span class="chip-dot" :class="'dot-' + role" />
            {{ ROLE_LABELS[role] || role }}
            <em>{{ stat.count }}</em>
          </button>
        </div>
      </div>
      <!-- 第二行：阶段筛选 -->
      <div class="filter-row">
        <span class="filter-row-label">阶段</span>
        <div class="filter-chips">
          <button class="chip" :class="{ active: activePhaseFilter === null }" @click="activePhaseFilter = null">
            全部阶段
          </button>
          <button
            v-for="(ph, pi) in PHASE_ROUNDS"
            :key="pi"
            class="chip chip-phase"
            :class="['phase-chip-' + pi, { active: activePhaseFilter === pi }]"
            @click="activePhaseFilter = activePhaseFilter === pi ? null : pi"
          >
            {{ ph.name }}
            <em>{{ phaseActionCount(pi) }}</em>
          </button>
        </div>
      </div>

      <!-- 第三行：智能体筛选 -->
      <div class="filter-row" v-if="agentList.length > 0">
        <span class="filter-row-label">智能体</span>
        <div class="filter-chips">
          <button
            class="chip"
            :class="{ active: activeAgentFilter === null }"
            @click="activeAgentFilter = null"
          >
            全部智能体
          </button>
          <button
            v-for="ag in agentList"
            :key="ag.id"
            class="chip chip-agent"
            :class="['chip-role-' + ag.role, { active: activeAgentFilter === ag.id }]"
            @click="activeAgentFilter = activeAgentFilter === ag.id ? null : ag.id; activeRoleFilter = null"
          >
            <span class="chip-dot" :class="'dot-' + ag.role" />
            {{ ag.name }}
            <em>{{ ag.count }}</em>
          </button>
        </div>
      </div>
    </div>

    <!-- 完整日志筛选栏 -->
    <div class="filter-panel" v-if="viewMode === 'full' && actions.length > 0">
      <div class="filter-row">
        <span class="filter-row-label">动作类型</span>
        <div class="filter-chips">
          <button class="chip" :class="{ active: activeTypeFilter === null }" @click="activeTypeFilter = null">
            全部 <em>{{ actions.length }}</em>
          </button>
          <button
            v-for="(cnt, type) in actionTypeStats"
            :key="type"
            class="chip"
            :class="[isSpeechType(type) ? 'chip-speech' : 'chip-sys', { active: activeTypeFilter === type }]"
            @click="activeTypeFilter = activeTypeFilter === type ? null : type"
          >
            {{ type }} <em>{{ cnt }}</em>
          </button>
        </div>
      </div>
    </div>

    <!-- ========= 发言视图 ========= -->
    <div class="speech-area" ref="speechAreaRef" v-show="viewMode === 'speech'">
      <div v-if="actions.length === 0" class="empty-hint">
        <div class="empty-icon">🔔</div>
        <p>庭审尚未开始，AI 正在就位，请稍候...</p>
      </div>

      <template v-for="(item, idx) in displayItems" :key="idx">

        <!-- 阶段/轮次分隔线 -->
        <div v-if="item.type === 'divider'" class="round-divider">
          <div class="divider-line" />
          <div class="divider-content">
            <span class="divider-phase" :class="'phase-' + item.phaseIndex">{{ item.phaseName }}</span>
            <span class="divider-round">第 {{ item.roundNum + 1 }} 轮</span>
            <span class="divider-count">{{ item.speechCount }} 发言 · {{ item.actionCount }} 动作</span>
          </div>
          <div class="divider-line" />
        </div>

        <!-- ===== 富文本发言卡片 ===== -->
        <div
          v-else-if="item.type === 'speech'"
          class="speech-card"
          :class="['align-' + getAlign(item.action), 'role-card-' + getCourtRole(item.action.agent_id)]"
        >
          <!-- 头部：头像 + 元信息 -->
          <div class="sc-head" :class="'align-' + getAlign(item.action)">
            <div class="sc-avatar" :style="{ background: getRoleColor(getCourtRole(item.action.agent_id)) }">
              {{ getAvatarLetter(getAgentDisplayName(item.action)) }}
            </div>
            <div class="sc-meta">
              <span class="sc-name" :style="{ color: getRoleColor(getCourtRole(item.action.agent_id)) }">
                {{ getAgentDisplayName(item.action) }}
              </span>
              <span class="sc-badge" :style="{ borderColor: getRoleColor(getCourtRole(item.action.agent_id)), color: getRoleColor(getCourtRole(item.action.agent_id)) }">
                {{ ROLE_LABELS[getCourtRole(item.action.agent_id)] || '参与人' }}
              </span>
              <span class="sc-action-type" :class="isSpeechType(item.action.action_type) ? 'atype-speech' : 'atype-sys'">
                {{ item.action.action_type }}
              </span>
              <span class="sc-round-tag">R{{ item.action.round_num + 1 }}</span>
              <span class="sc-phase-tag" :class="'phase-tag-' + getRoundPhase(item.action.round_num).phaseIndex">
                {{ getRoundPhase(item.action.round_num).phaseName }}
              </span>
            </div>
          </div>

          <!-- 发言内容 -->
          <div
            class="sc-bubble"
            :class="'align-' + getAlign(item.action)"
            :style="{ '--role-color': getRoleColor(getCourtRole(item.action.agent_id)) }"
          >
            <p class="sc-text">{{ getContent(item.action) }}</p>

            <!-- 附加参数（排除 content/text 字段，展示其余 args） -->
            <div v-if="getExtraArgs(item.action).length > 0" class="sc-extra-args">
              <span
                v-for="arg in getExtraArgs(item.action)"
                :key="arg.key"
                class="sc-arg-tag"
              >
                <span class="arg-key">{{ arg.key }}</span>
                <span class="arg-val">{{ arg.val }}</span>
              </span>
            </div>

            <!-- 底部元数据 -->
            <div class="sc-footer">
              <span v-if="item.action.platform" class="sc-footer-item">{{ item.action.platform }}</span>
              <span v-if="item.action.timestamp" class="sc-footer-item">{{ formatTime(item.action.timestamp) }}</span>
              <span v-if="item.action.success === false" class="sc-footer-fail">执行失败</span>
              <span v-else-if="item.action.result" class="sc-footer-result" :title="formatResult(item.action.result)">
                ✓ 已记录
              </span>
            </div>
          </div>
        </div>

        <!-- ===== 非发言动作（紧凑条） ===== -->
        <div
          v-else-if="item.type === 'action'"
          class="compact-action"
          :class="'align-' + getAlign(item.action)"
        >
          <span class="ca-dot" :class="'dot-' + getCourtRole(item.action.agent_id)" />
          <span class="ca-name" :style="{ color: getRoleColor(getCourtRole(item.action.agent_id)) }">
            {{ getAgentDisplayName(item.action) }}
          </span>
          <span class="ca-type">{{ item.action.action_type }}</span>
          <span v-for="arg in getExtraArgs(item.action).slice(0, 3)" :key="arg.key" class="ca-arg">
            {{ arg.key }}: {{ arg.val }}
          </span>
          <span v-if="item.action.success === false" class="ca-fail">✕</span>
        </div>

      </template>

      <div ref="scrollAnchorRef" />
    </div>

    <!-- ========= 完整日志视图 ========= -->
    <div class="speech-area" ref="fullLogRef" v-show="viewMode === 'full'">
      <div v-if="actions.length === 0" class="empty-hint">
        <div class="empty-icon">📋</div>
        <p>暂无动作记录</p>
      </div>

      <template v-for="(item, idx) in fullLogItems" :key="idx">
        <div v-if="item.type === 'divider'" class="round-divider">
          <div class="divider-line" />
          <div class="divider-content">
            <span class="divider-phase" :class="'phase-' + item.phaseIndex">{{ item.phaseName }}</span>
            <span class="divider-round">第 {{ item.roundNum + 1 }} 轮</span>
            <span class="divider-count">{{ item.count }} 个动作</span>
          </div>
          <div class="divider-line" />
        </div>

        <div
          v-else
          class="action-card"
          :class="['role-card-border-' + getCourtRole(item.action.agent_id), { 'is-speech': isSpeechAction(item.action), expanded: expandedActions.has(idx) }]"
        >
          <div class="action-card-head" @click="toggleExpand(idx)">
            <div class="action-meta">
              <span class="action-role-dot" :class="'dot-' + getCourtRole(item.action.agent_id)" />
              <span class="action-agent">{{ getAgentDisplayName(item.action) }}</span>
              <span class="action-role-label">{{ ROLE_LABELS[getCourtRole(item.action.agent_id)] || '' }}</span>
              <span class="action-type-badge" :class="isSpeechAction(item.action) ? 'badge-speech' : 'badge-system'">{{ item.action.action_type }}</span>
              <span v-if="item.action.success === false" class="action-failed">✕ 失败</span>
            </div>
            <div class="action-expand-hint">{{ expandedActions.has(idx) ? '▲ 收起' : '▼ 展开' }}</div>
          </div>
          <div v-if="isSpeechAction(item.action) && getContent(item.action)" class="action-content">{{ getContent(item.action) }}</div>
          <div v-if="expandedActions.has(idx)" class="action-data">
            <div class="data-section">
              <div class="data-label">action_args</div>
              <pre class="data-json">{{ JSON.stringify(item.action.action_args, null, 2) }}</pre>
            </div>
            <div v-if="item.action.result !== null && item.action.result !== undefined" class="data-section">
              <div class="data-label">result</div>
              <pre class="data-json result-json">{{ formatResult(item.action.result) }}</pre>
            </div>
            <div class="data-section data-meta-row">
              <span class="data-meta-item">轮次 <strong>{{ item.action.round_num }}</strong></span>
              <span class="data-meta-item">平台 <strong>{{ item.action.platform }}</strong></span>
              <span class="data-meta-item">时间 <strong>{{ item.action.timestamp }}</strong></span>
              <span class="data-meta-item">成功 <strong :class="item.action.success ? 'txt-ok' : 'txt-fail'">{{ item.action.success }}</strong></span>
            </div>
          </div>
        </div>
      </template>
      <div ref="fullLogAnchorRef" />
    </div>

    <!-- ========= 统计视图 ========= -->
    <div class="stats-area" v-show="viewMode === 'stats'">
      <div v-if="actions.length === 0" class="empty-hint">
        <div class="empty-icon">📊</div>
        <p>暂无统计数据</p>
      </div>
      <div v-else class="stats-content">

        <!-- 总体概况 -->
        <div class="stats-section">
          <div class="stats-section-title">总体概况</div>
          <div class="stats-grid">
            <div class="stats-card">
              <div class="stats-num">{{ actions.length }}</div>
              <div class="stats-label">总动作数</div>
            </div>
            <div class="stats-card">
              <div class="stats-num">{{ speechActions.length }}</div>
              <div class="stats-label">发言数</div>
            </div>
            <div class="stats-card">
              <div class="stats-num">{{ currentRound }}</div>
              <div class="stats-label">当前轮次 / {{ totalRounds }}</div>
            </div>
            <div class="stats-card">
              <div class="stats-num">{{ Object.keys(roundStats).length }}</div>
              <div class="stats-label">已完成轮次</div>
            </div>
            <div class="stats-card">
              <div class="stats-num">{{ Object.keys(roleStats).length }}</div>
              <div class="stats-label">参与角色种类</div>
            </div>
            <div class="stats-card">
              <div class="stats-num">{{ Object.keys(actionTypeStats).length }}</div>
              <div class="stats-label">动作类型种类</div>
            </div>
            <div class="stats-card">
              <div class="stats-num">{{ actions.filter(a => a.success === false).length }}</div>
              <div class="stats-label">失败动作数</div>
            </div>
            <div class="stats-card">
              <div class="stats-num stats-num-sm">{{ runnerStatus }}</div>
              <div class="stats-label">当前状态</div>
            </div>
          </div>
        </div>

        <!-- 各角色动作统计（全部动作 + 发言分项） -->
        <div class="stats-section">
          <div class="stats-section-title">
            各角色动作统计
            <span class="section-subtitle">条形 = 总动作 / 蓝色填充 = 发言数</span>
          </div>
          <div v-if="Object.keys(roleStats).length === 0" class="section-empty">暂无角色数据（角色映射加载中或模拟尚未开始）</div>
          <div v-else class="role-stats-list">
            <div v-for="(stat, role) in roleStats" :key="role" class="role-stats-row">
              <span class="role-dot-sm" :class="'dot-' + role" />
              <span class="role-name">{{ ROLE_LABELS[role] || role }}</span>
              <!-- 双层 bar：底层=总动作，覆盖层=发言数 -->
              <div class="role-bar-wrap">
                <div class="role-bar role-bar-total" :style="{ width: (stat.count / actions.length * 100) + '%' }" />
                <div class="role-bar role-bar-speech" :style="{ width: (stat.speechCount / actions.length * 100) + '%' }" />
              </div>
              <span class="role-count">
                <span class="cnt-total">{{ stat.count }}</span>
                <span class="cnt-sep">/</span>
                <span class="cnt-speech">{{ stat.speechCount }}</span>
              </span>
            </div>
            <div class="role-stats-legend">
              <span class="legend-item"><span class="legend-dot legend-total" />总动作</span>
              <span class="legend-item"><span class="legend-dot legend-speech" />发言</span>
            </div>
          </div>
        </div>

        <!-- 各轮次动作分布 -->
        <div class="stats-section">
          <div class="stats-section-title">各轮次动作分布</div>
          <div v-if="Object.keys(roundStats).length === 0" class="section-empty">暂无轮次数据</div>
          <div v-else class="round-stats-list">
            <div v-for="(roundData, rn) in roundStats" :key="rn" class="round-stats-row">
              <div class="round-header">
                <span class="round-label">
                  <span class="round-phase-dot" :class="'phase-' + getRoundPhase(Number(rn)).phaseIndex" />
                  第 {{ Number(rn) + 1 }} 轮
                  <span class="round-phase-name">{{ getRoundPhase(Number(rn)).phaseName }}</span>
                </span>
                <span class="round-total">{{ roundData.total }} 个动作</span>
              </div>
              <div class="round-agents">
                <div v-for="(agData, agId) in roundData.agents" :key="agId" class="round-agent-item">
                  <span class="agent-role-dot" :class="'dot-' + getCourtRole(Number(agId))" />
                  <span class="agent-name-sm">{{ agData.name }}</span>
                  <span class="agent-actions-sm">
                    <span
                      v-for="(cnt, atype) in agData.types"
                      :key="atype"
                      class="agent-type-tag"
                      :class="isSpeechType(atype) ? 'tag-speech' : 'tag-system'"
                    >{{ atype }}×{{ cnt }}</span>
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- 动作类型分布 -->
        <div class="stats-section">
          <div class="stats-section-title">动作类型分布</div>
          <div v-if="Object.keys(actionTypeStats).length === 0" class="section-empty">暂无动作数据</div>
          <div v-else class="type-stats-list">
            <div v-for="(cnt, type) in actionTypeStats" :key="type" class="type-stats-row">
              <span class="type-name" :class="isSpeechType(type) ? 'tag-speech' : 'tag-system'">{{ type }}</span>
              <div class="type-bar-wrap">
                <div
                  class="type-bar"
                  :class="isSpeechType(type) ? 'type-bar-speech' : 'type-bar-system'"
                  :style="{ width: (cnt / actions.length * 100) + '%' }"
                />
              </div>
              <span class="type-count">{{ cnt }}</span>
              <span class="type-pct">{{ Math.round(cnt / actions.length * 100) }}%</span>
            </div>
          </div>
        </div>

        <!-- 原始动作数据预览（最近10条） -->
        <div class="stats-section">
          <div class="stats-section-title">
            最新动作数据预览
            <span class="section-subtitle">最近 {{ Math.min(actions.length, 10) }} 条原始记录</span>
          </div>
          <div v-if="actions.length === 0" class="section-empty">暂无数据</div>
          <div v-else class="raw-actions-list">
            <div
              v-for="(a, i) in actions.slice(-10).reverse()"
              :key="i"
              class="raw-action-row"
            >
              <span class="raw-round">R{{ (a.round_num ?? 0) + 1 }}</span>
              <span class="raw-agent" :style="{ color: getRoleColor(getCourtRole(a.agent_id)) }">{{ getAgentDisplayName(a) }}</span>
              <span class="raw-type" :class="isSpeechType(a.action_type) ? 'tag-speech' : 'tag-system'">{{ a.action_type }}</span>
              <span class="raw-content">{{ getContent(a) || JSON.stringify(a.action_args).slice(0, 60) }}</span>
              <span v-if="a.success === false" class="raw-fail">✕</span>
            </div>
          </div>
        </div>

      </div>
    </div>

    <!-- 底部操作栏 -->
    <div class="courtroom-footer">
      <button class="btn-control" @click="toggleAutoScroll">
        {{ autoScroll ? '🔒 自动滚动：开' : '🔓 自动滚动：关' }}
      </button>
      <button class="btn-control" @click="expandAll" v-if="viewMode === 'full'">📂 全部展开</button>
      <button class="btn-control" @click="collapseAll" v-if="viewMode === 'full'">📁 全部折叠</button>
      <button class="btn-control btn-verdict" @click="goToVerdict" :disabled="!canGenerateVerdict">
        📋 生成判决预测报告
      </button>
      <span class="poll-hint">{{ runnerStatus === 'completed' ? '庭审已结束' : `每 ${pollInterval / 1000}s 刷新` }}</span>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, nextTick } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import CourtRoomTimeline from '../components/CourtRoomTimeline.vue'
import axios from 'axios'

const BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:5001'

const route = useRoute()
const router = useRouter()

const simulationId = computed(() => route.params.simulationId)

const caseName = ref(route.query.caseName || '')
const caseType = ref(route.query.caseType || 'civil')
const actions = ref([])
const currentRound = ref(0)
const totalRounds = ref(13)
const runnerStatus = ref('idle')
const totalActions = ref(0)

const agentRoleMap = ref({})
const agentNameMap = ref({})   // agentId → 真实姓名（来自 profiles）

// 视图模式
const viewMode = ref('speech')

// 发言视图筛选
const activeRoleFilter  = ref(null)
const activePhaseFilter = ref(null)   // 0-5 对应6个阶段
const activeAgentFilter = ref(null)   // 具体智能体 agent_id

// 完整日志筛选
const activeTypeFilter = ref(null)

// 完整日志展开
const expandedActions = ref(new Set())

// UI
const autoScroll = ref(true)
const speechAreaRef = ref(null)
const scrollAnchorRef = ref(null)
const fullLogAnchorRef = ref(null)
const pollInterval = 3000
let pollTimer = null

// 13轮 → 6阶段映射
const PHASE_ROUNDS = [
  { name: '开庭准备', rounds: [0, 1] },
  { name: '法庭调查', rounds: [2, 3, 4, 5, 6] },
  { name: '法庭辩论', rounds: [7, 8, 9] },
  { name: '最后陈述', rounds: [10] },
  { name: '休庭评议', rounds: [11] },
  { name: '宣判',     rounds: [12] },
]

const ROLE_LABELS = {
  judge:            '法官',
  plaintiff_counsel:'原告律师',
  defense_counsel:  '辩护律师',
  prosecutor:       '检察官',
  plaintiff:        '原告',
  defendant:        '被告',
  victim:           '被害人',
  witness:          '证人',
  expert:           '专家',
  court:            '法院',
  other:            '其他',
}

const ROLE_COLORS = {
  judge:            '#f59e0b',
  court:            '#f59e0b',
  plaintiff_counsel:'#3b82f6',
  defense_counsel:  '#ef4444',
  prosecutor:       '#a855f7',
  plaintiff:        '#60a5fa',
  defendant:        '#f87171',
  victim:           '#fb923c',
  witness:          '#4ade80',
  expert:           '#22d3ee',
  other:            '#64748b',
}

const ALIGN_MAP = {
  judge:            'center',
  court:            'center',
  plaintiff_counsel:'left',
  defense_counsel:  'right',
  prosecutor:       'left',
  plaintiff:        'left',
  defendant:        'right',
  victim:           'left',
  witness:          'center',
  expert:           'center',
  other:            'center',
}

function getRoundPhase(roundNum) {
  for (let i = 0; i < PHASE_ROUNDS.length; i++) {
    if (PHASE_ROUNDS[i].rounds.includes(roundNum)) {
      return { phaseIndex: i, phaseName: PHASE_ROUNDS[i].name }
    }
  }
  return { phaseIndex: -1, phaseName: `第${roundNum + 1}轮` }
}

function getPhaseIndexOfRound(roundNum) {
  return getRoundPhase(roundNum).phaseIndex
}

function getRoleColor(role) { return ROLE_COLORS[role] || ROLE_COLORS.other }
function getAlign(action) { return ALIGN_MAP[getCourtRole(action.agent_id)] || 'center' }
function getAvatarLetter(name) {
  if (!name) return '?'
  return name.charAt(name.length > 1 ? name.length - 1 : 0).toUpperCase()
}

const caseTypeLabel = computed(() =>
  ({ civil: '民事案件', criminal: '刑事案件' }[caseType.value] || '案件')
)

const statusClass = computed(() => ({
  running: 'status-running', starting: 'status-running',
  completed: 'status-done', stopped: 'status-done',
  failed: 'status-fail', idle: 'status-idle',
}[runnerStatus.value] || 'status-idle'))

const statusText = computed(() => ({
  running: '庭审进行中', starting: '准备启动',
  completed: '庭审已结束', stopped: '庭审已结束',
  failed: '模拟异常', idle: '等待开始',
}[runnerStatus.value] || '—'))

const canGenerateVerdict = computed(() => ['completed', 'stopped'].includes(runnerStatus.value))

const SPEECH_ACTIONS = new Set([
  'create_post', 'post', 'tweet', 'reply_post', 'reply', 'comment', 'quote_post', 'quote',
  'CREATE_POST', 'POST', 'TWEET', 'REPLY_POST', 'REPLY', 'COMMENT', 'QUOTE_POST', 'QUOTE',
])

function isSpeechType(type) { return SPEECH_ACTIONS.has(type || '') }

function isSpeechAction(action) {
  if (SPEECH_ACTIONS.has(action.action_type || '')) return true
  const args = action.action_args || {}
  return (args.content || args.text || args.post_content || args.comment || '').trim().length > 0
}

const speechActions = computed(() => actions.value.filter(isSpeechAction))

// 仅按阶段过滤后的列表（用于角色 chip 的计数）
const filteredByPhase = computed(() => {
  if (activePhaseFilter.value === null) return actions.value
  const phaseRounds = PHASE_ROUNDS[activePhaseFilter.value]?.rounds || []
  return actions.value.filter(a => phaseRounds.includes(a.round_num ?? 0))
})

// 阶段下的动作计数（发言视图用）
function phaseActionCount(phaseIdx) {
  const phaseRounds = PHASE_ROUNDS[phaseIdx]?.rounds || []
  return actions.value.filter(a => phaseRounds.includes(a.round_num ?? 0)).length
}

// 角色统计（在阶段过滤基础上）
const roleStatsFiltered = computed(() => {
  // 先统计当前阶段过滤后的实际计数
  const counts = {}
  for (const a of filteredByPhase.value) {
    const role = getCourtRole(a.agent_id)
    counts[role] = (counts[role] || 0) + 1
  }
  // 全部预定义角色都展示，没有数据的显示 0
  const stats = {}
  for (const role of Object.keys(ROLE_LABELS)) {
    stats[role] = { count: counts[role] || 0 }
  }
  // 补充数据里出现但不在预定义列表里的角色（如 other）
  for (const role of Object.keys(counts)) {
    if (!stats[role]) stats[role] = { count: counts[role] }
  }
  return stats
})

// 智能体列表（用于第三行筛选 chip）
// 以 profiles 为主，再补充 actions 里出现但没有 profile 的 agent
const agentList = computed(() => {
  const map = {}
  // 先从 agentNameMap/agentRoleMap 填充（来自 profiles）
  for (const [id, name] of Object.entries(agentNameMap.value)) {
    map[id] = { id: Number(id), name, role: agentRoleMap.value[id] || 'other', count: 0 }
  }
  // 统计 actions 里各 agent 的出现次数，并补充 profiles 里没有的
  for (const a of actions.value) {
    const id = a.agent_id
    if (id == null) continue
    if (!map[id]) {
      map[id] = {
        id,
        name: getAgentDisplayName(a),
        role: agentRoleMap.value[id] || 'other',
        count: 0,
      }
    }
    map[id].count++
  }
  // 按角色顺序排列（与 ROLE_LABELS 顺序一致）
  const roleOrder = Object.keys(ROLE_LABELS)
  return Object.values(map).sort((a, b) => {
    const ra = roleOrder.indexOf(a.role)
    const rb = roleOrder.indexOf(b.role)
    return (ra === -1 ? 99 : ra) - (rb === -1 ? 99 : rb)
  })
})

// 全局角色统计（统计视图用）—— 基于全部动作，附带发言数分项
const roleStats = computed(() => {
  const stats = {}
  for (const a of actions.value) {
    const role = getCourtRole(a.agent_id)
    if (!stats[role]) stats[role] = { count: 0, speechCount: 0, agentName: agentNameMap.value[a.agent_id] || (!/^agent\d*$/i.test(a.agent_name||'') ? a.agent_name : '') || ROLE_LABELS[role] || `#${a.agent_id}` }
    stats[role].count++
    if (isSpeechAction(a)) stats[role].speechCount++
  }
  return stats
})

const actionTypeStats = computed(() => {
  const stats = {}
  for (const a of actions.value) {
    const t = a.action_type || 'unknown'
    stats[t] = (stats[t] || 0) + 1
  }
  return stats
})

const roundStats = computed(() => {
  const byRound = {}
  for (const a of actions.value) {
    const rn = a.round_num ?? 0
    if (!byRound[rn]) byRound[rn] = { total: 0, agents: {} }
    byRound[rn].total++
    const agId = a.agent_id
    if (!byRound[rn].agents[agId]) byRound[rn].agents[agId] = { name: agentNameMap.value[agId] || (!/^agent\d*$/i.test(a.agent_name||'') ? a.agent_name : '') || `#${agId}`, types: {} }
    const t = a.action_type || 'unknown'
    byRound[rn].agents[agId].types[t] = (byRound[rn].agents[agId].types[t] || 0) + 1
  }
  return byRound
})

// 发言视图展示列表（支持角色 + 阶段双筛选，所有动作都显示）
const displayItems = computed(() => {
  let filtered = actions.value

  // 阶段筛选
  if (activePhaseFilter.value !== null) {
    const phaseRounds = PHASE_ROUNDS[activePhaseFilter.value]?.rounds || []
    filtered = filtered.filter(a => phaseRounds.includes(a.round_num ?? 0))
  }

  // 角色筛选（与智能体筛选互斥，智能体优先）
  if (activeAgentFilter.value !== null) {
    filtered = filtered.filter(a => a.agent_id === activeAgentFilter.value)
  } else if (activeRoleFilter.value !== null) {
    filtered = filtered.filter(a => getCourtRole(a.agent_id) === activeRoleFilter.value)
  }

  // 每轮的发言数和动作数统计
  const roundSpeechCount = {}
  const roundActionCount = {}
  for (const a of filtered) {
    const rn = a.round_num ?? 0
    roundActionCount[rn] = (roundActionCount[rn] || 0) + 1
    if (isSpeechAction(a)) roundSpeechCount[rn] = (roundSpeechCount[rn] || 0) + 1
  }

  const items = []
  let lastRound = -1

  for (const action of filtered) {
    const rn = action.round_num ?? 0
    if (rn !== lastRound) {
      const phase = getRoundPhase(rn)
      items.push({
        type: 'divider',
        roundNum: rn,
        phaseIndex: phase.phaseIndex,
        phaseName: phase.phaseName,
        speechCount: roundSpeechCount[rn] || 0,
        actionCount: roundActionCount[rn] || 0,
      })
      lastRound = rn
    }
    if (isSpeechAction(action)) {
      items.push({ type: 'speech', action })
    } else {
      items.push({ type: 'action', action })
    }
  }
  return items
})

// 完整日志展示列表
const fullLogItems = computed(() => {
  const filtered = activeTypeFilter.value
    ? actions.value.filter(a => a.action_type === activeTypeFilter.value)
    : actions.value

  const roundCount = {}
  for (const a of filtered) {
    const rn = a.round_num ?? 0
    roundCount[rn] = (roundCount[rn] || 0) + 1
  }

  const items = []
  let lastRound = -1
  for (const action of filtered) {
    const rn = action.round_num ?? 0
    if (rn !== lastRound) {
      const phase = getRoundPhase(rn)
      items.push({ type: 'divider', roundNum: rn, phaseIndex: phase.phaseIndex, phaseName: phase.phaseName, count: roundCount[rn] || 0 })
      lastRound = rn
    }
    items.push({ type: 'action', action })
  }
  return items
})

function getContent(action) {
  const args = action.action_args || {}
  return args.content || args.text || args.post_content || args.comment || ''
}

// 返回除 content/text/post_content/comment 之外的 action_args 字段
function getExtraArgs(action) {
  const SKIP = new Set(['content', 'text', 'post_content', 'comment'])
  const args = action.action_args || {}
  return Object.entries(args)
    .filter(([k]) => !SKIP.has(k) && args[k] !== null && args[k] !== undefined && args[k] !== '')
    .map(([k, v]) => ({
      key: k,
      val: typeof v === 'object' ? JSON.stringify(v) : String(v).slice(0, 60),
    }))
}

function formatTime(ts) {
  if (!ts) return ''
  try {
    return new Date(ts).toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit', second: '2-digit' })
  } catch {
    return String(ts).slice(11, 19) || ts
  }
}

function formatResult(result) {
  if (result === null || result === undefined) return ''
  if (typeof result === 'object') return JSON.stringify(result, null, 2)
  return String(result)
}

function getCourtRole(agentId) { return agentRoleMap.value[agentId] || 'other' }

function toggleExpand(idx) {
  const set = new Set(expandedActions.value)
  if (set.has(idx)) set.delete(idx)
  else set.add(idx)
  expandedActions.value = set
}
function expandAll() {
  const set = new Set()
  fullLogItems.value.forEach((item, idx) => { if (item.type === 'action') set.add(idx) })
  expandedActions.value = set
}
function collapseAll() { expandedActions.value = new Set() }

function extractCourtRoleFromTopics(topics) {
  if (!Array.isArray(topics)) return null
  for (const t of topics) {
    const m = String(t).match(/^court_role[：:]\s*(\w+)$/i)
    if (m) return m[1]
  }
  return null
}

function inferRoleFromType(entityType) {
  const t = (entityType || '').toLowerCase().replace(/[_\s]/g, '')
  const map = { judge: 'judge', lawyer: 'plaintiff_counsel', defenselawyer: 'defense_counsel', prosecutor: 'prosecutor', plaintiff: 'plaintiff', defendant: 'defendant', victim: 'victim', witness: 'witness', expert: 'expert', court: 'court', lawfirm: 'court', prosecutionoffice: 'prosecutor' }
  return map[t] || 'other'
}

async function loadAgentRoleMap() {
  const roleMap = {}
  const nameMap = {}
  try {
    const res = await axios.get(`${BASE_URL}/api/simulation/${simulationId.value}/profiles?platform=twitter`)
    for (const p of res.data?.data?.profiles || []) {
      const uid = p.user_id ?? p.agent_id
      if (uid == null) continue
      // 角色映射
      let role = extractCourtRoleFromTopics(p.interested_topics)
      if (!role && p.court_role) role = p.court_role
      if (!role) role = inferRoleFromType(p.entity_type || p.source_entity_type || '')
      roleMap[uid] = role || 'other'
      // 真实姓名映射
      const realName = p.name || p.user_name || p.username || ''
      if (realName) nameMap[uid] = realName
    }
  } catch { /* 静默降级 */ }
  try {
    const res = await axios.get(`${BASE_URL}/api/simulation/${simulationId.value}/config`)
    for (const cfg of res.data?.data?.agent_configs || []) {
      const id = cfg.agent_id ?? cfg.user_id
      if (id == null) continue
      if (!roleMap[id]) roleMap[id] = inferRoleFromType(cfg.entity_type || '')
      if (!nameMap[id] && cfg.entity_name) nameMap[id] = cfg.entity_name
    }
  } catch { /* 静默降级 */ }
  agentRoleMap.value = roleMap
  agentNameMap.value = nameMap
}

function getAgentDisplayName(action) {
  const realName = agentNameMap.value[action.agent_id]
  if (realName) return realName
  // 过滤掉 OASIS 通用名"Agent0"/"Agent1"等，改用角色中文名
  const rawName = action.agent_name || ''
  if (/^agent\d*$/i.test(rawName.trim())) {
    const role = agentRoleMap.value[action.agent_id] || 'other'
    return ROLE_LABELS[role] || rawName || `#${action.agent_id}`
  }
  return rawName || `#${action.agent_id}`
}

async function pollStatus() {
  try {
    const res = await axios.get(`${BASE_URL}/api/simulation/${simulationId.value}/run-status/detail`)
    const data = res.data?.data || {}
    runnerStatus.value = data.runner_status || 'idle'
    currentRound.value = data.current_round || 0
    totalRounds.value = data.total_rounds || 13

    const allActions = (data.all_actions || []).slice().sort((a, b) => (a.round_num ?? 0) - (b.round_num ?? 0))
    totalActions.value = allActions.length

    if (allActions.length > actions.value.length) {
      actions.value = allActions
      if (autoScroll.value) {
        await nextTick()
        scrollAnchorRef.value?.scrollIntoView({ behavior: 'smooth' })
        fullLogAnchorRef.value?.scrollIntoView({ behavior: 'smooth' })
      }
    }
    if (['completed', 'failed', 'stopped'].includes(runnerStatus.value)) stopPolling()
  } catch (err) {
    console.error('轮询庭审状态失败:', err)
  }
}

function startPolling() {
  if (pollTimer) return
  pollStatus()
  pollTimer = setInterval(pollStatus, pollInterval)
}
function stopPolling() {
  if (pollTimer) { clearInterval(pollTimer); pollTimer = null }
}
function toggleAutoScroll() { autoScroll.value = !autoScroll.value }

async function goToVerdict() {
  router.push({ path: '/verdict-generate', query: { simulationId: simulationId.value, graphId: route.query.graphId || '', caseName: caseName.value } })
}

onMounted(() => { loadAgentRoleMap(); startPolling() })
onUnmounted(() => { stopPolling() })
</script>

<style scoped>
/* ============ 基础布局 ============ */
.courtroom-view {
  display: flex;
  flex-direction: column;
  height: 100vh;
  background: #070d14;
  color: #e2e8f0;
  font-family: 'Inter', 'PingFang SC', sans-serif;
  overflow: hidden;
}

/* Header */
.courtroom-header {
  padding: 12px 20px;
  background: #0f1923;
  border-bottom: 1px solid #1e3a5f;
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-shrink: 0;
  gap: 12px;
}
.case-info { display: flex; align-items: center; gap: 10px; flex-shrink: 0; }
.back-btn {
  display: flex; align-items: center; justify-content: center;
  width: 32px; height: 32px;
  background: rgba(59,130,246,0.1);
  border: 1px solid rgba(59,130,246,0.25);
  border-radius: 8px;
  color: #60a5fa;
  cursor: pointer;
  transition: all 0.2s;
  flex-shrink: 0;
}
.back-btn:hover { background: rgba(59,130,246,0.2); border-color: #3b82f6; transform: translateX(-2px); }
.back-icon { width: 16px; height: 16px; }
.case-icon { font-size: 26px; }
.case-title { margin: 0; font-size: 15px; font-weight: 700; color: #f8fafc; }
.case-type-badge { font-size: 11px; color: #60a5fa; background: rgba(37,99,235,0.12); border: 1px solid rgba(37,99,235,0.3); border-radius: 4px; padding: 1px 7px; }

.header-center { flex: 1; display: flex; justify-content: center; }
.view-mode-tabs { display: flex; background: #0a1520; border: 1px solid #1e3a5f; border-radius: 8px; overflow: hidden; }
.mode-tab { padding: 5px 16px; font-size: 12px; color: #475569; background: transparent; border: none; cursor: pointer; transition: all 0.15s; }
.mode-tab:hover { color: #93c5fd; }
.mode-tab.active { background: rgba(37,99,235,0.2); color: #60a5fa; font-weight: 600; }

.status-row { display: flex; align-items: center; gap: 8px; flex-shrink: 0; }
.status-dot { width: 8px; height: 8px; border-radius: 50%; }
.status-running { background: #22c55e; box-shadow: 0 0 6px #22c55e; animation: blink 1.2s infinite; }
.status-done    { background: #3b82f6; }
.status-fail    { background: #ef4444; }
.status-idle    { background: #475569; }
@keyframes blink { 0%,100%{opacity:1} 50%{opacity:.3} }
.status-text { font-size: 13px; color: #94a3b8; }
.action-count { font-size: 11px; color: #475569; }

/* Timeline */
.timeline-wrapper { padding: 10px 20px; border-bottom: 1px solid #1e3a5f; flex-shrink: 0; }

/* ============ 双行筛选面板 ============ */
.filter-panel {
  background: #0a1520;
  border-bottom: 1px solid #1e3a5f;
  flex-shrink: 0;
  padding: 0;
}
.filter-row {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 7px 20px;
  border-bottom: 1px solid #0f1923;
}
.filter-row:last-child { border-bottom: none; }
.filter-row-label { font-size: 11px; color: #334155; flex-shrink: 0; width: 28px; }
.filter-chips { display: flex; flex-wrap: wrap; gap: 5px; }

.chip {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 3px 10px;
  border-radius: 20px;
  font-size: 11px;
  cursor: pointer;
  border: 1px solid #1e3a5f;
  background: #0f1923;
  color: #475569;
  transition: all 0.15s;
}
.chip:hover { border-color: #2563eb44; color: #94a3b8; }
.chip.active { background: rgba(37,99,235,0.15); border-color: #2563eb; color: #93c5fd; }
.chip em { font-style: normal; font-size: 10px; background: rgba(255,255,255,0.07); border-radius: 8px; padding: 0 5px; }
.chip-dot { width: 6px; height: 6px; border-radius: 50%; flex-shrink: 0; }

/* 角色 chip 颜色 */
.chip-role-judge.active               { border-color: #d97706; color: #fbbf24; background: rgba(217,119,6,0.12); }
.chip-role-plaintiff_counsel.active   { border-color: #2563eb; color: #60a5fa; background: rgba(37,99,235,0.12); }
.chip-role-defense_counsel.active     { border-color: #ef4444; color: #f87171; background: rgba(239,68,68,0.12); }
.chip-role-prosecutor.active          { border-color: #a855f7; color: #c084fc; background: rgba(168,85,247,0.12); }
.chip-role-plaintiff.active           { border-color: #60a5fa; color: #93c5fd; background: rgba(96,165,250,0.12); }
.chip-role-defendant.active           { border-color: #f87171; color: #fca5a5; background: rgba(248,113,113,0.12); }
.chip-role-witness.active             { border-color: #4ade80; color: #86efac; background: rgba(74,222,128,0.12); }
.chip-role-expert.active              { border-color: #22d3ee; color: #67e8f9; background: rgba(34,211,238,0.12); }

/* 阶段 chip 颜色 */
.phase-chip-0.active { border-color: #475569; color: #94a3b8; background: rgba(71,85,105,0.15); }
.phase-chip-1.active { border-color: #2563eb; color: #60a5fa; background: rgba(37,99,235,0.12); }
.phase-chip-2.active { border-color: #b45309; color: #fbbf24; background: rgba(180,83,9,0.12); }
.phase-chip-3.active { border-color: #7c3aed; color: #a78bfa; background: rgba(124,58,237,0.12); }
.phase-chip-4.active { border-color: #065f46; color: #34d399; background: rgba(6,95,70,0.12); }
.phase-chip-5.active { border-color: #d97706; color: #fbbf24; background: rgba(217,119,6,0.15); }

.chip-speech.active { border-color: #2563eb; color: #60a5fa; background: rgba(37,99,235,0.12); }
.chip-sys.active    { border-color: #475569; color: #94a3b8; background: rgba(71,85,105,0.12); }

/* 智能体 chip */
.chip-agent { display: flex; align-items: center; gap: 4px; max-width: 180px; }
.chip-agent .chip-dot { flex-shrink: 0; }
.chip-role-sub {
  font-size: 10px;
  color: #475569;
  border-left: 1px solid #1e3a5f;
  padding-left: 5px;
  margin-left: 2px;
  white-space: nowrap;
  flex-shrink: 0;
}
.chip-agent.active .chip-role-sub { color: inherit; opacity: 0.7; border-color: currentColor; }

/* ============ 滚动区域 ============ */
.speech-area {
  flex: 1;
  overflow-y: auto;
  padding: 14px 20px;
  scroll-behavior: smooth;
}
.speech-area::-webkit-scrollbar { width: 4px; }
.speech-area::-webkit-scrollbar-thumb { background: #1e3a5f; border-radius: 2px; }

.empty-hint { display: flex; flex-direction: column; align-items: center; justify-content: center; height: 200px; color: #475569; gap: 12px; }
.empty-icon { font-size: 40px; opacity: 0.4; }

/* ============ 轮次分隔线 ============ */
.round-divider { display: flex; align-items: center; gap: 10px; margin: 20px 0 12px; padding: 0 4px; }
.divider-line { flex: 1; height: 1px; background: #1a2f45; }
.divider-content { display: flex; align-items: center; gap: 8px; flex-shrink: 0; }
.divider-phase { font-size: 11px; font-weight: 600; padding: 3px 12px; border-radius: 10px; border: 1px solid; }
.divider-round { font-size: 11px; color: #475569; }
.divider-count { font-size: 10px; color: #334155; background: #0a1520; padding: 2px 8px; border-radius: 8px; }
.phase-0  { color: #94a3b8; border-color: #334155; background: rgba(148,163,184,0.08); }
.phase-1  { color: #60a5fa; border-color: #1d4ed8; background: rgba(37,99,235,0.1); }
.phase-2  { color: #fbbf24; border-color: #b45309; background: rgba(180,83,9,0.1); }
.phase-3  { color: #a78bfa; border-color: #7c3aed; background: rgba(124,58,237,0.1); }
.phase-4  { color: #34d399; border-color: #065f46; background: rgba(6,95,70,0.1); }
.phase-5  { color: #fbbf24; border-color: #d97706; background: rgba(217,119,6,0.12); }
.phase--1 { color: #475569; border-color: #334155; background: rgba(71,85,105,0.1); }

/* ============ 富文本发言卡片 ============ */
.speech-card {
  display: flex;
  flex-direction: column;
  margin-bottom: 18px;
  max-width: 100%;
}
.speech-card.align-left  { align-items: flex-start; }
.speech-card.align-right { align-items: flex-end; }
.speech-card.align-center { align-items: center; }

/* 卡片头部 */
.sc-head { display: flex; align-items: center; gap: 8px; margin-bottom: 6px; flex-wrap: wrap; }
.sc-head.align-right { flex-direction: row-reverse; }

.sc-avatar {
  width: 30px; height: 30px; border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  font-size: 12px; font-weight: 700; color: #fff; flex-shrink: 0;
}
.sc-meta { display: flex; align-items: center; gap: 6px; flex-wrap: wrap; }
.sc-name { font-size: 13px; font-weight: 700; }
.sc-badge {
  font-size: 10px; border: 1px solid; border-radius: 4px;
  padding: 1px 6px; flex-shrink: 0;
}
.sc-action-type {
  font-size: 10px; border-radius: 4px; padding: 1px 7px;
  font-family: monospace; flex-shrink: 0;
}
.atype-speech { background: rgba(37,99,235,0.15); color: #60a5fa; border: 1px solid rgba(37,99,235,0.25); }
.atype-sys    { background: rgba(71,85,105,0.15);  color: #64748b; border: 1px solid rgba(71,85,105,0.2); }
.sc-round-tag { font-size: 10px; color: #334155; flex-shrink: 0; }
.sc-phase-tag {
  font-size: 10px; border-radius: 4px; padding: 1px 6px; flex-shrink: 0; border: 1px solid;
}
.phase-tag-0  { color: #94a3b8; border-color: #33415544; background: rgba(148,163,184,0.06); }
.phase-tag-1  { color: #60a5fa; border-color: #1d4ed844; background: rgba(37,99,235,0.07); }
.phase-tag-2  { color: #fbbf24; border-color: #b4530944; background: rgba(180,83,9,0.07); }
.phase-tag-3  { color: #a78bfa; border-color: #7c3aed44; background: rgba(124,58,237,0.07); }
.phase-tag-4  { color: #34d399; border-color: #065f4644; background: rgba(6,95,70,0.07); }
.phase-tag-5  { color: #fbbf24; border-color: #d9770644; background: rgba(217,119,6,0.08); }
.phase-tag--1 { color: #475569; border-color: #33415544; background: rgba(71,85,105,0.06); }

/* 气泡 */
.sc-bubble {
  max-width: 72%;
  background: #0d1e30;
  border: 1px solid #1a2f45;
  border-radius: 10px;
  padding: 12px 16px;
  border-left: 3px solid var(--role-color, #2563eb);
  position: relative;
}
.sc-bubble.align-right {
  border-left: 1px solid #1a2f45;
  border-right: 3px solid var(--role-color, #ef4444);
}
.sc-bubble.align-center {
  max-width: 88%;
  border-left: 3px solid var(--role-color, #f59e0b);
}

.sc-text {
  margin: 0;
  font-size: 14px;
  color: #cbd5e1;
  line-height: 1.7;
  white-space: pre-wrap;
  word-break: break-word;
}

/* 附加参数 */
.sc-extra-args {
  display: flex;
  flex-wrap: wrap;
  gap: 5px;
  margin-top: 8px;
  padding-top: 8px;
  border-top: 1px solid #1a2f45;
}
.sc-arg-tag {
  display: inline-flex;
  align-items: center;
  gap: 3px;
  font-size: 11px;
  background: #060e18;
  border: 1px solid #1e3a5f;
  border-radius: 4px;
  padding: 2px 7px;
}
.arg-key { color: #475569; font-family: monospace; }
.arg-val { color: #7dd3fc; max-width: 180px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-family: monospace; }

/* 气泡底部元数据 */
.sc-footer {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 8px;
  padding-top: 6px;
  border-top: 1px solid #1a2f4544;
  flex-wrap: wrap;
}
.sc-footer-item { font-size: 10px; color: #334155; }
.sc-footer-fail { font-size: 10px; color: #ef4444; }
.sc-footer-result { font-size: 10px; color: #22c55e; cursor: help; }

/* ============ 紧凑动作条（非发言动作） ============ */
.compact-action {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 4px 10px;
  margin-bottom: 4px;
  background: #0a1520;
  border: 1px solid #1a2f45;
  border-radius: 6px;
  font-size: 11px;
  max-width: 80%;
  flex-wrap: wrap;
}
.compact-action.align-left  { align-self: flex-start; margin-left: 38px; }
.compact-action.align-right { align-self: flex-end;   margin-right: 38px; }
.compact-action.align-center { align-self: center; }
.ca-dot { width: 6px; height: 6px; border-radius: 50%; flex-shrink: 0; }
.ca-name { font-weight: 600; }
.ca-type { font-family: monospace; color: #475569; background: #060e18; border: 1px solid #1e3a5f; border-radius: 3px; padding: 0 5px; }
.ca-arg  { color: #334155; }
.ca-fail { color: #ef4444; }

/* ============ 角色色点（通用） ============ */
.dot-judge              { background: #f59e0b; }
.dot-court              { background: #f59e0b; }
.dot-plaintiff_counsel  { background: #3b82f6; }
.dot-defense_counsel    { background: #ef4444; }
.dot-prosecutor         { background: #a855f7; }
.dot-plaintiff          { background: #60a5fa; }
.dot-defendant          { background: #f87171; }
.dot-victim             { background: #fb923c; }
.dot-witness            { background: #4ade80; }
.dot-expert             { background: #22d3ee; }
.dot-other              { background: #475569; }

/* ============ 完整日志动作卡片 ============ */
.action-card {
  background: #0d1e30; border: 1px solid #1a2f45; border-radius: 8px;
  margin-bottom: 8px; overflow: hidden; transition: border-color 0.15s;
}
.action-card.is-speech { border-color: #1d4ed844; }
.action-card.expanded  { border-color: #2563eb; }
.role-card-border-judge              { border-left: 3px solid #f59e0b; }
.role-card-border-court              { border-left: 3px solid #f59e0b; }
.role-card-border-plaintiff_counsel  { border-left: 3px solid #3b82f6; }
.role-card-border-defense_counsel    { border-left: 3px solid #ef4444; }
.role-card-border-prosecutor         { border-left: 3px solid #a855f7; }
.role-card-border-plaintiff          { border-left: 3px solid #60a5fa; }
.role-card-border-defendant          { border-left: 3px solid #f87171; }
.role-card-border-witness            { border-left: 3px solid #4ade80; }
.role-card-border-expert             { border-left: 3px solid #22d3ee; }
.action-card-head { display: flex; align-items: center; justify-content: space-between; padding: 8px 14px; cursor: pointer; user-select: none; }
.action-card-head:hover { background: rgba(37,99,235,0.06); }
.action-meta { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
.action-role-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }
.action-agent { font-size: 13px; font-weight: 600; color: #e2e8f0; }
.action-role-label { font-size: 11px; color: #64748b; background: #0f1923; border: 1px solid #1e3a5f; border-radius: 4px; padding: 1px 6px; }
.action-type-badge { font-size: 11px; border-radius: 4px; padding: 1px 8px; font-family: monospace; }
.badge-speech { background: rgba(37,99,235,0.15); color: #60a5fa; border: 1px solid rgba(37,99,235,0.3); }
.badge-system { background: rgba(71,85,105,0.15); color: #64748b; border: 1px solid rgba(71,85,105,0.3); }
.action-failed { font-size: 11px; color: #ef4444; }
.action-expand-hint { font-size: 11px; color: #334155; flex-shrink: 0; }
.action-content { padding: 8px 14px 10px; font-size: 14px; color: #cbd5e1; line-height: 1.6; border-top: 1px solid #1a2f45; white-space: pre-wrap; word-break: break-word; }
.action-data { padding: 0 14px 12px; border-top: 1px solid #1e3a5f; }
.data-section { margin-top: 10px; }
.data-label { font-size: 11px; color: #475569; margin-bottom: 4px; font-family: monospace; }
.data-json { background: #060e18; border: 1px solid #1e3a5f; border-radius: 6px; padding: 10px 14px; font-size: 12px; color: #7dd3fc; font-family: monospace; overflow-x: auto; max-height: 300px; overflow-y: auto; white-space: pre; margin: 0; }
.result-json { color: #86efac; }
.data-meta-row { display: flex; flex-wrap: wrap; gap: 12px; }
.data-meta-item { font-size: 11px; color: #475569; }
.data-meta-item strong { color: #94a3b8; }
.txt-ok { color: #22c55e; }
.txt-fail { color: #ef4444; }

/* ============ 统计视图 ============ */
.stats-area { flex: 1; overflow-y: auto; padding: 16px 20px; }
.stats-area::-webkit-scrollbar { width: 4px; }
.stats-area::-webkit-scrollbar-thumb { background: #1e3a5f; border-radius: 2px; }
.stats-content { display: flex; flex-direction: column; gap: 18px; }
.stats-section { background: #0d1e30; border: 1px solid #1a2f45; border-radius: 10px; padding: 16px; }
.stats-section-title { font-size: 12px; font-weight: 600; color: #94a3b8; margin-bottom: 12px; padding-bottom: 8px; border-bottom: 1px solid #1e3a5f; text-transform: uppercase; letter-spacing: 0.05em; }
.stats-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; }
@media (max-width: 900px) { .stats-grid { grid-template-columns: repeat(2, 1fr); } }
.stats-card { background: #060e18; border: 1px solid #1e3a5f; border-radius: 8px; padding: 14px; text-align: center; }
.stats-num { font-size: 28px; font-weight: 700; color: #60a5fa; line-height: 1; margin-bottom: 6px; }
.stats-num-sm { font-size: 13px; font-weight: 600; color: #60a5fa; }
.stats-label { font-size: 11px; color: #475569; }
.section-subtitle { font-size: 10px; color: #334155; font-weight: 400; margin-left: 8px; }
.section-empty { font-size: 12px; color: #334155; padding: 12px 0; font-style: italic; }
.role-stats-list { display: flex; flex-direction: column; gap: 8px; }
.role-stats-row { display: flex; align-items: center; gap: 10px; }
.role-dot-sm { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }
.role-name { font-size: 12px; color: #94a3b8; width: 80px; flex-shrink: 0; }
.role-bar-wrap { flex: 1; height: 10px; background: #0a1520; border-radius: 4px; overflow: hidden; position: relative; }
.role-bar { height: 100%; border-radius: 4px; transition: width 0.4s; position: absolute; top: 0; left: 0; }
.role-bar-total  { background: rgba(71,85,105,0.5); }
.role-bar-speech { background: #3b82f6; }
.role-count { font-size: 11px; width: 52px; text-align: right; flex-shrink: 0; display: flex; align-items: center; justify-content: flex-end; gap: 1px; }
.cnt-total  { color: #64748b; }
.cnt-sep    { color: #334155; font-size: 10px; }
.cnt-speech { color: #60a5fa; }
.role-stats-legend { display: flex; gap: 12px; margin-top: 10px; padding-top: 8px; border-top: 1px solid #1a2f45; }
.legend-item { display: flex; align-items: center; gap: 5px; font-size: 11px; color: #475569; }
.legend-dot  { width: 10px; height: 6px; border-radius: 2px; }
.legend-total  { background: rgba(71,85,105,0.5); }
.legend-speech { background: #3b82f6; }
.round-stats-list { display: flex; flex-direction: column; gap: 10px; }
.round-stats-row { background: #060e18; border: 1px solid #1e3a5f; border-radius: 8px; padding: 10px 14px; }
.round-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; }
.round-label { display: flex; align-items: center; gap: 6px; font-size: 12px; color: #94a3b8; font-weight: 600; }
.round-phase-dot { width: 6px; height: 6px; border-radius: 50%; }
.round-phase-name { font-size: 11px; color: #475569; }
.round-total { font-size: 11px; color: #475569; }
.round-agents { display: flex; flex-direction: column; gap: 4px; }
.round-agent-item { display: flex; align-items: center; gap: 8px; }
.agent-role-dot { width: 6px; height: 6px; border-radius: 50%; flex-shrink: 0; }
.agent-name-sm { font-size: 11px; color: #64748b; width: 100px; flex-shrink: 0; }
.agent-actions-sm { display: flex; flex-wrap: wrap; gap: 4px; }
.agent-type-tag { font-size: 10px; border-radius: 3px; padding: 1px 6px; font-family: monospace; }
.tag-speech { background: rgba(37,99,235,0.12); color: #60a5fa; border: 1px solid rgba(37,99,235,0.2); }
.tag-system { background: rgba(71,85,105,0.12); color: #475569; border: 1px solid rgba(71,85,105,0.2); }
.type-stats-list { display: flex; flex-direction: column; gap: 8px; }
.type-stats-row { display: flex; align-items: center; gap: 10px; }
.type-name { font-size: 11px; border-radius: 4px; padding: 1px 8px; width: 140px; flex-shrink: 0; font-family: monospace; text-align: center; }
.type-bar-wrap { flex: 1; height: 8px; background: #0a1520; border-radius: 4px; overflow: hidden; }
.type-bar { height: 100%; border-radius: 4px; transition: width 0.4s; }
.type-bar-speech { background: #2563eb; }
.type-bar-system { background: #374151; }
.type-count { font-size: 12px; color: #475569; width: 30px; text-align: right; }
.type-pct   { font-size: 10px; color: #334155; width: 30px; text-align: right; }

/* 原始数据预览 */
.raw-actions-list { display: flex; flex-direction: column; gap: 4px; }
.raw-action-row {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 6px 10px;
  background: #060e18;
  border: 1px solid #1a2f45;
  border-radius: 6px;
  font-size: 11px;
  overflow: hidden;
}
.raw-round  { color: #334155; font-family: monospace; flex-shrink: 0; width: 28px; }
.raw-agent  { font-weight: 600; flex-shrink: 0; max-width: 90px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.raw-type   { font-family: monospace; font-size: 10px; border-radius: 3px; padding: 1px 6px; flex-shrink: 0; }
.raw-content { color: #64748b; flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.raw-fail   { color: #ef4444; flex-shrink: 0; }

/* ============ Footer ============ */
.courtroom-footer { padding: 10px 20px; background: #0f1923; border-top: 1px solid #1e3a5f; display: flex; align-items: center; gap: 10px; flex-shrink: 0; }
.btn-control { background: #1e3a5f; border: 1px solid #2563eb; color: #93c5fd; border-radius: 6px; padding: 5px 12px; font-size: 12px; cursor: pointer; transition: background 0.2s; }
.btn-control:hover:not(:disabled) { background: #1d4ed8; color: #fff; }
.btn-control:disabled { opacity: 0.4; cursor: not-allowed; }
.btn-verdict { background: rgba(37,99,235,0.2); border-color: #3b82f6; }
.poll-hint { font-size: 11px; color: #334155; margin-left: auto; }
</style>
