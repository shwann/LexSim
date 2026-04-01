<template>
  <div class="court-timeline">
    <div class="timeline-track">
      <div
        v-for="(phase, idx) in phases"
        :key="idx"
        class="phase-item"
        :class="{
          'phase-completed': currentPhase > idx,
          'phase-active': currentPhase === idx,
          'phase-pending': currentPhase < idx,
        }"
      >
        <!-- 连接线（第一个节点无左线） -->
        <div v-if="idx > 0" class="connector" :class="{ 'connector-done': currentPhase > idx - 1 }" />

        <!-- 节点圆圈 -->
        <div class="phase-dot">
          <span v-if="currentPhase > idx" class="dot-icon">✓</span>
          <span v-else-if="currentPhase === idx" class="dot-icon pulse">●</span>
          <span v-else class="dot-number">{{ idx + 1 }}</span>
        </div>

        <!-- 标签 -->
        <div class="phase-label">{{ phase.name }}</div>

        <!-- 当前阶段进度提示 -->
        <div v-if="currentPhase === idx" class="phase-badge">进行中</div>
      </div>
    </div>

    <!-- 当前轮次显示 -->
    <div class="round-info">
      <span class="round-label">当前轮次</span>
      <span class="round-value">{{ currentRound }} / {{ totalRounds }}</span>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  // 当前模拟轮次（0-12）
  currentRound: {
    type: Number,
    default: 0,
  },
  // 总轮次
  totalRounds: {
    type: Number,
    default: 13,
  },
})

const phases = [
  { name: '开庭准备', rounds: [0, 1] },
  { name: '法庭调查', rounds: [2, 3, 4, 5, 6] },
  { name: '法庭辩论', rounds: [7, 8, 9] },
  { name: '最后陈述', rounds: [10] },
  { name: '休庭评议', rounds: [11] },
  { name: '宣  判', rounds: [12] },
]

const currentPhase = computed(() => {
  for (let i = phases.length - 1; i >= 0; i--) {
    if (phases[i].rounds.includes(props.currentRound)) return i
    if (props.currentRound > Math.max(...phases[i].rounds)) return i + 1
  }
  return 0
})
</script>

<style scoped>
.court-timeline {
  background: #0f1923;
  border: 1px solid #1e3a5f;
  border-radius: 12px;
  padding: 20px 24px 16px;
}

.timeline-track {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  position: relative;
}

.phase-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  position: relative;
  flex: 1;
  min-width: 0;
}

/* 连接线 */
.connector {
  position: absolute;
  left: calc(-50% + 14px);
  top: 14px;
  width: calc(100% - 28px);
  height: 2px;
  background: #1e3a5f;
  z-index: 0;
}
.connector-done {
  background: #2563eb;
}

/* 节点圆圈 */
.phase-dot {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
  font-weight: 700;
  z-index: 1;
  position: relative;
  transition: all 0.3s ease;
}
.phase-completed .phase-dot {
  background: #2563eb;
  color: #fff;
  box-shadow: 0 0 8px rgba(37, 99, 235, 0.6);
}
.phase-active .phase-dot {
  background: #1d4ed8;
  color: #fff;
  box-shadow: 0 0 12px rgba(29, 78, 216, 0.8);
  border: 2px solid #60a5fa;
}
.phase-pending .phase-dot {
  background: #1e3a5f;
  color: #64748b;
  border: 2px solid #1e3a5f;
}

.dot-icon {
  font-size: 11px;
}

/* 脉冲动画 */
.pulse {
  animation: pulse-anim 1.5s infinite;
}
@keyframes pulse-anim {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.4; }
}

/* 标签 */
.phase-label {
  margin-top: 8px;
  font-size: 11px;
  text-align: center;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  max-width: 70px;
  transition: color 0.3s ease;
}
.phase-completed .phase-label { color: #60a5fa; }
.phase-active .phase-label { color: #93c5fd; font-weight: 600; }
.phase-pending .phase-label { color: #475569; }

/* 进行中标记 */
.phase-badge {
  margin-top: 4px;
  font-size: 9px;
  color: #60a5fa;
  background: rgba(37, 99, 235, 0.15);
  border: 1px solid rgba(37, 99, 235, 0.3);
  border-radius: 4px;
  padding: 1px 5px;
}

/* 底部轮次信息 */
.round-info {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  gap: 8px;
  margin-top: 14px;
  padding-top: 10px;
  border-top: 1px solid #1e3a5f;
}
.round-label {
  font-size: 11px;
  color: #475569;
}
.round-value {
  font-size: 13px;
  font-weight: 600;
  color: #60a5fa;
  font-variant-numeric: tabular-nums;
}
</style>
