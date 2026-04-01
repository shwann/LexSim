<template>
  <div class="bubble-wrapper" :class="alignClass">
    <!-- 角色头像 + 名称 -->
    <div class="bubble-meta" :class="alignClass">
      <div class="role-avatar" :style="{ background: roleColor }">
        {{ roleInitial }}
      </div>
      <span class="role-name" :style="{ color: roleColor }">{{ displayName }}</span>
      <span class="role-badge" :style="{ borderColor: roleColor, color: roleColor }">
        {{ roleBadge }}
      </span>
      <span class="round-tag">R{{ roundNum }}</span>
    </div>

    <!-- 发言气泡 -->
    <div
      class="bubble-content"
      :class="alignClass"
      :style="{ borderLeftColor: roleColor, borderRightColor: roleColor }"
    >
      <p class="bubble-text">{{ content }}</p>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  // court_role: judge / plaintiff_counsel / defense_counsel /
  //             prosecutor / plaintiff / defendant / victim /
  //             witness / expert / court / other
  courtRole: {
    type: String,
    default: 'other',
  },
  agentName: {
    type: String,
    default: '',
  },
  content: {
    type: String,
    default: '',
  },
  roundNum: {
    type: Number,
    default: 0,
  },
  actionType: {
    type: String,
    default: 'CREATE_POST',
  },
})

// 角色颜色映射
const ROLE_COLORS = {
  judge:            '#f59e0b',  // 金色 - 法官
  court:            '#f59e0b',  // 金色 - 法院
  plaintiff_counsel:'#3b82f6',  // 蓝色 - 原告律师
  defense_counsel:  '#ef4444',  // 红色 - 辩护律师
  prosecutor:       '#a855f7',  // 紫色 - 检察官
  plaintiff:        '#60a5fa',  // 浅蓝 - 原告
  defendant:        '#f87171',  // 浅红 - 被告
  victim:           '#fb923c',  // 橙色 - 被害人
  witness:          '#4ade80',  // 绿色 - 证人
  expert:           '#22d3ee',  // 青色 - 专家
  other:            '#94a3b8',  // 灰色 - 其他
}

// 角色标签映射
const ROLE_BADGES = {
  judge:            '法官',
  court:            '法院',
  plaintiff_counsel:'原告律师',
  defense_counsel:  '辩护律师',
  prosecutor:       '检察官',
  plaintiff:        '原告',
  defendant:        '被告',
  victim:           '被害人',
  witness:          '证人',
  expert:           '专家证人',
  other:            '参与人',
}

// 法官和法院居中，原告侧左，被告侧右
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

const roleColor = computed(() => ROLE_COLORS[props.courtRole] || ROLE_COLORS.other)
const roleBadge = computed(() => ROLE_BADGES[props.courtRole] || '参与人')
const alignClass = computed(() => {
  const a = ALIGN_MAP[props.courtRole] || 'center'
  return `align-${a}`
})
const displayName = computed(() => props.agentName || roleBadge.value)
const roleInitial = computed(() => {
  const n = displayName.value
  return n.charAt(n.length > 1 ? n.length - 1 : 0).toUpperCase()
})
</script>

<style scoped>
.bubble-wrapper {
  display: flex;
  flex-direction: column;
  margin-bottom: 16px;
  max-width: 100%;
}

/* 对齐方式 */
.align-left  { align-items: flex-start; }
.align-right { align-items: flex-end; }
.align-center { align-items: center; }

/* 元信息行 */
.bubble-meta {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-bottom: 5px;
}

/* 头像 */
.role-avatar {
  width: 26px;
  height: 26px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 11px;
  font-weight: 700;
  color: #fff;
  flex-shrink: 0;
}

.role-name {
  font-size: 13px;
  font-weight: 600;
}

.role-badge {
  font-size: 10px;
  border: 1px solid;
  border-radius: 4px;
  padding: 0 5px;
  line-height: 16px;
}

.round-tag {
  font-size: 10px;
  color: #475569;
  margin-left: 2px;
}

/* 气泡正文 */
.bubble-content {
  max-width: 72%;
  background: #111827;
  border: 1px solid #1e3a5f;
  border-radius: 10px;
  padding: 10px 14px;
  border-left-width: 3px;
  position: relative;
}

.bubble-content.align-right {
  border-left-width: 1px;
  border-right-width: 3px;
  border-right-color: inherit;
}

/* 居中气泡宽一些 */
.bubble-content.align-center {
  max-width: 86%;
  border-left-color: #f59e0b !important;
}

.bubble-text {
  margin: 0;
  font-size: 13px;
  color: #cbd5e1;
  line-height: 1.6;
  white-space: pre-wrap;
  word-break: break-word;
}
</style>
