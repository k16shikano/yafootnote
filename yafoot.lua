push_footnotes_below_lines = function (head, group)
   for item in node.traverse_id(node.id("whatsit"), head) do
      local is_footnote = node.has_attribute(item, 100)
      if is_footnote
      then
         local footnote = node.copy(tex.box[is_footnote])
         head, new = node.insert_after(head, item, footnote)         
         node.set_attribute(new, 200, is_footnote)

         item = item.next
         new.width = 0
      end
   end
   return head
end

crush_height_of_hlist = function (head, group, size)
   local acc_height = 0
   local acc_depth = 0

   recur = function (head, list_head)
      acc_height = 0
      acc_depth = 0
      for item in node.traverse(head) do
         if item.id == node.id("vlist")
         then
            list_head = recur_vlist(item, list_head)
         elseif item.id == node.id("hlist")
         then
            list_head = recur_hlist(item, list_head)
         end
      end
      return list_head
   end

   recur_hlist = function (hlist, list_head)
      list_head = recur(hlist.head, list_head)
      return list_head
   end

   recur_vlist = function (vlist, list_head)
      local footnotebox = node.has_attribute(vlist, 200)

      if footnotebox then
         footnote_node = node.copy(tex.box[footnotebox])
         acc_height = acc_height + footnote_node.height
         acc_depth = acc_depth + footnote_node.depth

         vlist.height = vlist.height - acc_height
         vlist.depth = acc_depth
--         node.set_attribute(vlist, 300, 1)
         acc_height = 0 -- acc_height - vlist.height
         acc_depth = 0 -- acc_depth - vlist.depth
      else
         if vlist.head
         then
            acc_height = 0 -- acc_height - vlist.height
            acc_depth = 0 -- acc_depth - vlist.depth
            list_head = recur(vlist.head, list_head)
         end
      end
      acc_height = 0 -- acc_height - vlist.height
      acc_depth = 0 -- acc_depth - vlist.depth
      return list_head
   end

   recur(head, head)

--[[
   recur_acc = function (head, list_head)
      for item in node.traverse(head) do
         if item.id == node.id("vlist")
         then
            list_head = recur_acc_vlist(item, list_head)
         elseif item.id == node.id("hlist")
         then
            list_head = recur_acc_hlist(item, list_head)
         end
      end
      return list_head
   end

   recur_acc_hlist = function (hlist, list_head)
      list_head = recur_acc(hlist.head, list_head)
      return list_head
   end

   recur_acc_vlist = function (vlist, list_head)
      local footnotebox = node.has_attribute(vlist, 200)

      if footnotebox then
         footnote_node = node.copy(tex.box[footnotebox])
         acc_height = acc_height + footnote_node.height
         acc_depth = acc_depth + footnote_node.depth
      else
         if vlist.head
         then
            list_head = recur_acc(vlist.head, list_head)
         end
      end
      return list_head
   end
   
   for vitem in node.traverse_id(node.id("vlist"), head) do
      if node.has_attribute(vitem, 200)
      then
         if not node.has_attribute(vitem, 300)
         then
            recur_acc(vitem, head)
            vitem.height = vitem.height - acc_height
            vitem.depth = acc_depth
            acc_height = 0
            acc_depth = 0
         end
      end
   end
--]]
   
   return head
end

move_footnote_bottom = function (page_head, group, s)
   local footins = node.new("vlist")
   footins.list, new = node.insert_before(footins.list, footins.list, node.copy(tex.box.footins))
   
   recur = function (head, under_hlist, page_head)
      for item in node.traverse(head) do
         if item.id == node.id("vlist")
         then
            page_head = recur_vlist(item, under_hlist, page_head)
         elseif item.id == node.id("hlist")
         then
            page_head = recur_hlist(item, page_head)
         end
      end
      return page_head
   end

   recur_hlist = function (hlist, page_head)
      page_head = recur(hlist.head, true, page_head)
      return page_head
   end

   recur_vlist = function (vlist, under_hlist, page_head)
      local footnotebox = node.has_attribute(vlist, 200)

      if footnotebox then
         footnote = node.copy(tex.box[footnotebox])
         page_head = node.remove(page_head, vlist)
         if footins
         then
            footins.list, new = node.insert_after(footins.list, footins.tail, footnote)
         end         
      else
         if vlist.head
         then
            page_head = recur(vlist.head, under_hlist, page_head)
         end
      end
      return page_head
   end

   page_head = recur(page_head, false, page_head)
   if footins.list
   then
      tex.box.footins = node.copy(node.vpack(footins.list))
   end
   return page_head
end

