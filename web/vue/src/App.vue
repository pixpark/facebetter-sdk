<template>
  <router-view />
</template>

<script setup>
</script>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  background: #f0f0f0; /* 浅灰色背景，与白色容器区分 */
}

#app {
  width: 100%;
  height: 100vh;
  overflow: hidden;
  background: #f0f0f0; /* 浅灰色背景，与白色容器区分 */
}
</style>
